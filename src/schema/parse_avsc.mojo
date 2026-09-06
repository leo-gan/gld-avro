from std.collections import List

from json.emit import emit_json
from json.parse import parse_json
from json.value import (
    JSON_ARRAY,
    JSON_OBJECT,
    JSON_STRING,
    JsonDoc,
)
from schema.model import (
    ST_ARRAY,
    ST_BOOL,
    ST_BYTES,
    ST_DOUBLE,
    ST_ENUM,
    ST_FIXED,
    ST_FLOAT,
    ST_INT,
    ST_LONG,
    ST_MAP,
    ST_NULL,
    ST_RECORD,
    ST_REF,
    ST_STRING,
    ST_UNION,
    SchemaError,
    SchemaNode,
    SchemaPool,
)


def _is_name_start(c: Int) -> Bool:
    return (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95


def _is_name_part(c: Int) -> Bool:
    return _is_name_start(c) or (c >= 48 and c <= 57)


def _valid_name(s: String) -> Bool:
    if s.byte_length() == 0:
        return False
    var b = s.as_bytes()
    if not _is_name_start(Int(b[0])):
        return False
    var i = 1
    while i < len(b):
        if not _is_name_part(Int(b[i])):
            return False
        i += 1
    return True


def _prim_kind(name: String) -> Int:
    if name == "null":
        return ST_NULL
    if name == "boolean":
        return ST_BOOL
    if name == "int":
        return ST_INT
    if name == "long":
        return ST_LONG
    if name == "float":
        return ST_FLOAT
    if name == "double":
        return ST_DOUBLE
    if name == "bytes":
        return ST_BYTES
    if name == "string":
        return ST_STRING
    return -1


def _fullname(name: String, ns: String) -> String:
    var b = name.as_bytes()
    var i = 0
    while i < len(b):
        if Int(b[i]) == 46:
            return name
        i += 1
    if ns.byte_length() == 0:
        return name
    return ns + "." + name


def _namespace_of(full: String) -> String:
    var b = full.as_bytes()
    var last = -1
    var i = 0
    while i < len(b):
        if Int(b[i]) == 46:
            last = i
        i += 1
    if last < 0:
        return String()
    var out = List[Byte]()
    var j = 0
    while j < last:
        out.append(b[j])
        j += 1
    try:
        return String(from_utf8=out)
    except _:
        return String()


def parse_schema(
    mut pool: SchemaPool, doc: JsonDoc, id: Int, ns: String
) raises SchemaError -> Int:
    var k = doc.kind(id)
    if k == JSON_STRING:
        return _named(pool, doc.as_string(id), ns)
    if k == JSON_ARRAY:
        return _union(pool, doc, id, ns)
    if k == JSON_OBJECT:
        return _object(pool, doc, id, ns)
    raise SchemaError("schema must be string, array, or object")


def _named(mut pool: SchemaPool, name: String, ns: String) raises SchemaError -> Int:
    var pk = _prim_kind(name)
    if pk >= 0:
        var n = SchemaNode()
        n.kind = pk
        return pool.add(n)
    var full = _fullname(name, ns)
    var existing = pool.find_name(full)
    if existing < 0:
        existing = pool.find_name(name)
    if existing < 0:
        raise SchemaError("unknown type: " + name)
    var r = SchemaNode()
    r.kind = ST_REF
    r.ref_id = existing
    return pool.add(r)


def _union(
    mut pool: SchemaPool, doc: JsonDoc, id: Int, ns: String
) raises SchemaError -> Int:
    var n = doc.nodes[id].count
    if n == 0:
        raise SchemaError("empty union")
    var node = SchemaNode()
    node.kind = ST_UNION
    var uid = pool.add(node)
    var seen_prim = List[Int]()
    var i = 0
    while i < n:
        var bid = parse_schema(pool, doc, doc.child(id, i), ns)
        var bk = pool.kind_of(bid)
        if bk == ST_UNION:
            raise SchemaError("nested union")
        if bk != ST_RECORD and bk != ST_ENUM and bk != ST_FIXED and bk != ST_REF:
            var s = 0
            while s < len(seen_prim):
                if seen_prim[s] == bk:
                    raise SchemaError("duplicate union branch kind")
                s += 1
            seen_prim.append(bk)
        pool.add_branch(uid, bid)
        i += 1
    return uid


def _decl_ns(doc: JsonDoc, id: Int, outer: String) -> String:
    var n = doc.find(id, String("namespace"))
    if n >= 0 and doc.kind(n) == JSON_STRING:
        return doc.as_string(n)
    return outer


def _object(
    mut pool: SchemaPool, doc: JsonDoc, id: Int, ns: String
) raises SchemaError -> Int:
    var type_id = doc.find(id, String("type"))
    if type_id < 0:
        raise SchemaError("object schema missing type")
    var tk = doc.kind(type_id)
    if tk == JSON_ARRAY or tk == JSON_OBJECT:
        return parse_schema(pool, doc, type_id, ns)
    if tk != JSON_STRING:
        raise SchemaError("type must be string, array, or object")
    var tname = doc.as_string(type_id)
    var pk = _prim_kind(tname)
    if pk >= 0:
        var n = SchemaNode()
        n.kind = pk
        var lt = doc.find(id, String("logicalType"))
        if lt >= 0 and doc.kind(lt) == JSON_STRING:
            n.logical_type = doc.as_string(lt)
        return pool.add(n)
    if tname == "record":
        return _record(pool, doc, id, ns)
    if tname == "enum":
        return _enum(pool, doc, id, ns)
    if tname == "array":
        return _array(pool, doc, id, ns)
    if tname == "map":
        return _map(pool, doc, id, ns)
    if tname == "fixed":
        return _fixed(pool, doc, id, ns)
    return _named(pool, tname, ns)


def _record(
    mut pool: SchemaPool, doc: JsonDoc, id: Int, ns: String
) raises SchemaError -> Int:
    var name_id = doc.find(id, String("name"))
    if name_id < 0:
        raise SchemaError("record missing name")
    var raw = doc.as_string(name_id)
    var dns = _decl_ns(doc, id, ns)
    var full = _fullname(raw, dns)
    var node = SchemaNode()
    node.kind = ST_RECORD
    node.name = full
    node.namespace = _namespace_of(full)
    var rec_ns = node.namespace
    var self_id = pool.add(node)
    var fields_id = doc.find(id, String("fields"))
    if fields_id < 0 or doc.kind(fields_id) != JSON_ARRAY:
        raise SchemaError("record missing fields")
    var i = 0
    var n = doc.nodes[fields_id].count
    while i < n:
        var fid = doc.child(fields_id, i)
        var fname_id = doc.find(fid, String("name"))
        if fname_id < 0:
            raise SchemaError("field missing name")
        var fname = doc.as_string(fname_id)
        var ft = doc.find(fid, String("type"))
        if ft < 0:
            raise SchemaError("field missing type")
        var ftid = parse_schema(pool, doc, ft, rec_ns)
        var has_def = False
        var defj = String()
        var def_id = doc.find(fid, String("default"))
        if def_id >= 0:
            has_def = True
            defj = emit_json(doc, def_id)
        pool.add_field(self_id, fname, ftid, has_def, defj)
        i += 1
    return self_id


def _enum(
    mut pool: SchemaPool, doc: JsonDoc, id: Int, ns: String
) raises SchemaError -> Int:
    var name_id = doc.find(id, String("name"))
    if name_id < 0:
        raise SchemaError("enum missing name")
    var dns = _decl_ns(doc, id, ns)
    var node = SchemaNode()
    node.kind = ST_ENUM
    node.name = _fullname(doc.as_string(name_id), dns)
    node.namespace = _namespace_of(node.name)
    var eid = pool.add(node)
    var syms = doc.find(id, String("symbols"))
    if syms < 0 or doc.kind(syms) != JSON_ARRAY:
        raise SchemaError("enum missing symbols")
    var i = 0
    var n = doc.nodes[syms].count
    while i < n:
        pool.add_symbol(eid, doc.as_string(doc.child(syms, i)))
        i += 1
    var ed = doc.find(id, String("default"))
    if ed >= 0:
        pool.nodes[eid].enum_default = doc.as_string(ed)
    return eid


def _array(
    mut pool: SchemaPool, doc: JsonDoc, id: Int, ns: String
) raises SchemaError -> Int:
    var items = doc.find(id, String("items"))
    if items < 0:
        raise SchemaError("array missing items")
    var node = SchemaNode()
    node.kind = ST_ARRAY
    node.item_id = parse_schema(pool, doc, items, ns)
    return pool.add(node)


def _map(
    mut pool: SchemaPool, doc: JsonDoc, id: Int, ns: String
) raises SchemaError -> Int:
    var values = doc.find(id, String("values"))
    if values < 0:
        raise SchemaError("map missing values")
    var node = SchemaNode()
    node.kind = ST_MAP
    node.value_id = parse_schema(pool, doc, values, ns)
    return pool.add(node)


def _fixed(
    mut pool: SchemaPool, doc: JsonDoc, id: Int, ns: String
) raises SchemaError -> Int:
    var name_id = doc.find(id, String("name"))
    var size_id = doc.find(id, String("size"))
    if name_id < 0 or size_id < 0:
        raise SchemaError("fixed missing name or size")
    var dns = _decl_ns(doc, id, ns)
    var node = SchemaNode()
    node.kind = ST_FIXED
    node.name = _fullname(doc.as_string(name_id), dns)
    node.namespace = _namespace_of(node.name)
    node.size = Int(doc.as_int(size_id))
    return pool.add(node)


def parse_avsc(text: String) raises SchemaError -> SchemaPool:
    var doc: JsonDoc
    try:
        doc = parse_json(text)
    except _:
        raise SchemaError("invalid JSON schema")
    var pool = SchemaPool()
    pool.original_json = text
    pool.root = parse_schema(pool, doc, doc.root, String())
    return pool^

from std.collections import List

from schema.model import SchemaError, SchemaPool
from schema.parse_avpr import parse_avpr
from schema.parse_avsc import parse_avsc


def parse_avdl(text: String) raises SchemaError -> SchemaPool:
    return parse_avsc(_idl_to_avsc(text))


def parse_avdl(text: String, from_file: String) raises SchemaError -> SchemaPool:
    var json = _idl_to_avsc(text)
    var p = 0
    var extra = List[String]()
    while True:
        var ip = _find_from(text, String("import "), p)
        if ip < 0:
            break
        p = ip + 7
        var kind = _ident_at(text, _skip_ws(text, p))
        var qs = _find_from(text, String("\""), p)
        if qs < 0:
            raise SchemaError("IDL: import missing path")
        var path = _until(text, qs + 1, 34)
        var body = _read_rel(from_file, path)
        if kind == "idl":
            extra.append(_idl_to_avsc(body))
        elif kind == "schema":
            extra.append(body)
        elif kind == "protocol":
            extra.append(parse_avpr(body).original_json)
        else:
            raise SchemaError("IDL: unknown import kind")
        p = qs + path.byte_length() + 1
    if len(extra) == 0:
        return parse_avsc(json)
    extra.append(json)
    var arr = String("[")
    var i = 0
    while i < len(extra):
        if i > 0:
            arr += ","
        arr += extra[i]
        i += 1
    arr += "]"
    return parse_avsc(arr)


def _idl_to_avsc(text: String) raises SchemaError -> String:
    var ns = String()
    var npos = _find_from(text, String("@namespace(\""), 0)
    if npos >= 0:
        ns = _until(text, npos + 12, 34)
    var types = List[String]()
    var pos = 0
    var guard = 0
    while guard < 64:
        guard += 1
        var kp = _next_decl(text, pos)
        if kp < 0:
            break
        var kind = _ident_at(text, kp)
        if kind == "record" or kind == "error":
            types.append(_convert_record(text, kp, ns))
            pos = _after_block(text, _find_from(text, String("{"), kp))
        elif kind == "enum":
            types.append(_convert_enum(text, kp, ns))
            pos = _after_block(text, _find_from(text, String("{"), kp))
        else:
            pos = kp + kind.byte_length()
    if len(types) == 0:
        raise SchemaError("IDL: no record")
    if len(types) == 1:
        return types[0]
    var json = String("[")
    var i = 0
    while i < len(types):
        if i > 0:
            json += ","
        json += types[i]
        i += 1
    json += "]"
    return json


def _convert_record(text: String, rec_pos: Int, ns: String) raises SchemaError -> String:
    var after_kw = _skip_ws(text, rec_pos + _ident_at(text, rec_pos).byte_length())
    var name = _ident_at(text, after_kw)
    if name.byte_length() == 0:
        raise SchemaError("IDL: record missing name")
    var brace = _find_from(text, String("{"), rec_pos)
    if brace < 0:
        raise SchemaError("IDL: record missing body")
    var end = _after_block(text, brace)
    var body = _slice(text, brace + 1, end - 1)
    var json = String("{\"type\":\"record\",\"name\":\"") + name + "\""
    if ns.byte_length() > 0:
        json += ",\"namespace\":\"" + ns + "\""
    json += ",\"fields\":["
    var first = True
    var i = 0
    var guard = 0
    while i < body.byte_length() and guard < 256:
        guard += 1
        i = _skip_ws(body, i)
        if i >= body.byte_length():
            break
        if _byte(body, i) == 64:
            var par = _find_from(body, String("("), i)
            if par >= 0:
                var cl = _find_from(body, String(")"), par)
                if cl >= 0:
                    i = cl + 1
                    continue
            i += 1
            continue
        var ty = _type_at(body, i)
        i = _skip_ws(body, i + _type_span(body, i))
        var fname = _ident_at(body, i)
        if fname.byte_length() == 0:
            break
        i = _skip_ws(body, i + fname.byte_length())
        var defj = String()
        if i < body.byte_length() and _byte(body, i) == 61:
            i = _skip_ws(body, i + 1)
            defj = _literal_at(body, i)
            i += _literal_span(body, i)
        var semi = _find_from(body, String(";"), i)
        if semi < 0:
            raise SchemaError("IDL: field missing ;")
        i = semi + 1
        if not first:
            json += ","
        first = False
        json += "{\"name\":\"" + fname + "\",\"type\":" + ty
        if defj.byte_length() > 0:
            json += ",\"default\":" + defj
        json += "}"
    json += "]}"
    return json


def _convert_enum(text: String, pos: Int, ns: String) -> String:
    var name = _ident_at(text, _skip_ws(text, pos + 4))
    var brace = _find_from(text, String("{"), pos)
    var end = _after_block(text, brace)
    var body = _slice(text, brace + 1, end - 1)
    var json = String("{\"type\":\"enum\",\"name\":\"") + name + "\""
    if ns.byte_length() > 0:
        json += ",\"namespace\":\"" + ns + "\""
    json += ",\"symbols\":["
    var first = True
    var i = 0
    while i < body.byte_length():
        i = _skip_ws(body, i)
        if i >= body.byte_length():
            break
        if _byte(body, i) == 44:
            i += 1
            continue
        var sym = _ident_at(body, i)
        if sym.byte_length() == 0:
            break
        if not first:
            json += ","
        first = False
        json += "\"" + sym + "\""
        i += sym.byte_length()
    json += "]}"
    return json


def _type_at(text: String, start: Int) -> String:
    var i = _skip_ws(text, start)
    if _starts_at(text, i, String("array")):
        var inner = _type_at(text, _find_from(text, String("<"), i) + 1)
        var t = "{\"type\":\"array\",\"items\":" + inner + "}"
        if _has_q(text, start):
            return "[\"null\"," + t + "]"
        return t
    if _starts_at(text, i, String("map")):
        var inner = _type_at(text, _find_from(text, String("<"), i) + 1)
        var t = "{\"type\":\"map\",\"values\":" + inner + "}"
        if _has_q(text, start):
            return "[\"null\"," + t + "]"
        return t
    if _starts_at(text, i, String("union")):
        return _union_at(text, i)
    var id = _ident_at(text, i)
    var t = "\"" + id + "\""
    var after = _skip_ws(text, i + id.byte_length())
    if after < text.byte_length() and _byte(text, after) == 63:
        return "[\"null\"," + t + "]"
    return t


def _union_at(text: String, start: Int) -> String:
    var brace = _find_from(text, String("{"), start)
    var end = _after_block(text, brace)
    var body = _slice(text, brace + 1, end - 1)
    var s = String("[")
    var first = True
    var i = 0
    while i < body.byte_length():
        i = _skip_ws(body, i)
        if i >= body.byte_length():
            break
        if _byte(body, i) == 44:
            i += 1
            continue
        var t = _type_at(body, i)
        if not first:
            s += ","
        first = False
        s += t
        i += _type_span(body, i)
    s += "]"
    return s


def _type_span(text: String, start: Int) -> Int:
    var i = _skip_ws(text, start)
    if _starts_at(text, i, String("array")) or _starts_at(text, i, String("map")):
        var open_a = _find_from(text, String("<"), i)
        var close_a = _find_from(text, String(">"), open_a)
        i = close_a + 1
    elif _starts_at(text, i, String("union")):
        i = _after_block(text, _find_from(text, String("{"), i))
    else:
        i += _ident_at(text, i).byte_length()
    i = _skip_ws(text, i)
    if i < text.byte_length() and _byte(text, i) == 63:
        i += 1
    return i - start


def _has_q(text: String, start: Int) -> Bool:
    var i = start + _type_span(text, start) - 1
    return i >= 0 and i < text.byte_length() and _byte(text, i) == 63


def _literal_at(text: String, start: Int) -> String:
    var i = _skip_ws(text, start)
    if _starts_at(text, i, String("null")):
        return String("null")
    if _starts_at(text, i, String("true")):
        return String("true")
    if _starts_at(text, i, String("false")):
        return String("false")
    if _byte(text, i) == 34:
        return "\"" + _until(text, i + 1, 34) + "\""
    if _byte(text, i) == 45 or (_byte(text, i) >= 48 and _byte(text, i) <= 57):
        return _number_at(text, i)
    return "\"" + _ident_at(text, i) + "\""


def _literal_span(text: String, start: Int) -> Int:
    var i = _skip_ws(text, start)
    if _starts_at(text, i, String("null")):
        return 4
    if _starts_at(text, i, String("true")):
        return 4
    if _starts_at(text, i, String("false")):
        return 5
    if _byte(text, i) == 34:
        return _until(text, i + 1, 34).byte_length() + 2
    if _byte(text, i) == 45 or (_byte(text, i) >= 48 and _byte(text, i) <= 57):
        return _number_at(text, i).byte_length()
    return _ident_at(text, i).byte_length()


def _number_at(text: String, start: Int) -> String:
    var i = start
    if _byte(text, i) == 45:
        i += 1
    while i < text.byte_length():
        var c = _byte(text, i)
        if (c >= 48 and c <= 57) or c == 46:
            i += 1
        else:
            break
    return _slice(text, start, i)


def _next_decl(text: String, start: Int) -> Int:
    var keys = List[String]()
    keys.append(String("record "))
    keys.append(String("error "))
    keys.append(String("enum "))
    var best = -1
    var i = 0
    while i < len(keys):
        var p = _find_from(text, keys[i], start)
        if p >= 0 and (best < 0 or p < best):
            best = p
        i += 1
    return best


def _after_block(text: String, brace: Int) -> Int:
    if brace < 0:
        return text.byte_length()
    var depth = 0
    var i = brace
    while i < text.byte_length():
        var c = _byte(text, i)
        if c == 123:
            depth += 1
        elif c == 125:
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    return text.byte_length()


def _find_from(text: String, pat: String, start: Int) -> Int:
    var tb = text.as_bytes()
    var pb = pat.as_bytes()
    if len(pb) == 0 or start + len(pb) > len(tb):
        return -1
    var i = start
    while i <= len(tb) - len(pb):
        var ok = True
        var j = 0
        while j < len(pb):
            if tb[i + j] != pb[j]:
                ok = False
                break
            j += 1
        if ok:
            return i
        i += 1
    return -1


def _starts_at(text: String, i: Int, word: String) -> Bool:
    var wb = word.as_bytes()
    var tb = text.as_bytes()
    if i + len(wb) > len(tb):
        return False
    var j = 0
    while j < len(wb):
        if tb[i + j] != wb[j]:
            return False
        j += 1
    return True


def _ident_at(text: String, start: Int) -> String:
    var i = _skip_ws(text, start)
    if i >= text.byte_length():
        return String()
    var c = _byte(text, i)
    if not ((c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95):
        return String()
    var j = i + 1
    while j < text.byte_length():
        var d = _byte(text, j)
        if (d >= 65 and d <= 90) or (d >= 97 and d <= 122) or d == 95 or (d >= 48 and d <= 57):
            j += 1
        else:
            break
    return _slice(text, i, j)


def _skip_ws(text: String, start: Int) -> Int:
    var i = start
    while i < text.byte_length():
        var c = _byte(text, i)
        if c == 32 or c == 9 or c == 10 or c == 13:
            i += 1
        else:
            return i
    return i


def _byte(text: String, i: Int) -> Int:
    return Int(text.as_bytes()[i])


def _slice(text: String, start: Int, end: Int) -> String:
    var out = List[Byte]()
    var b = text.as_bytes()
    var i = start
    while i < end and i < len(b):
        out.append(b[i])
        i += 1
    try:
        return String(from_utf8=out)
    except _:
        return String()


def _until(text: String, start: Int, stop: Int) -> String:
    var i = start
    while i < text.byte_length() and _byte(text, i) != stop:
        i += 1
    return _slice(text, start, i)


def _read_rel(from_file: String, path: String) raises SchemaError -> String:
    var b = from_file.as_bytes()
    var last = -1
    var i = 0
    while i < len(b):
        if Int(b[i]) == 47:
            last = i
        i += 1
    var full = path
    if last > 0:
        full = _slice(from_file, 0, last) + "/" + path
    try:
        var f = open(full, "r")
        var s = String(f.read())
        f.close()
        return s
    except _:
        raise SchemaError("import not found: " + path)

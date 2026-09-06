from std.collections import List, Span

from runtime.error import DecodeError
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
    SchemaPool,
)
from wire.reader import WireReader
from wire.writer import WireWriter


comptime AV_NULL = 0
comptime AV_BOOL = 1
comptime AV_INT = 2
comptime AV_LONG = 3
comptime AV_FLOAT = 4
comptime AV_DOUBLE = 5
comptime AV_BYTES = 6
comptime AV_STRING = 7
comptime AV_ENUM = 8
comptime AV_FIXED = 9
comptime AV_ARRAY = 10
comptime AV_MAP = 11
comptime AV_RECORD = 12
comptime AV_UNION = 13


struct AvroNode(Copyable, Movable, Defaultable, ImplicitlyCopyable):
    var kind: Int
    var b: Bool
    var i: Int64
    var s: String
    var first: Int
    var count: Int
    var schema_id: Int

    def __init__(out self):
        self.kind = AV_NULL
        self.b = False
        self.i = 0
        self.s = String()
        self.first = 0
        self.count = 0
        self.schema_id = -1


struct GenericDatum(Movable):
    var pool: SchemaPool
    var nodes: List[AvroNode]
    var bytes_store: List[Byte]
    var bytes_start: List[Int]
    var bytes_len: List[Int]
    var refs: List[Int]
    var root: Int

    def __init__(out self, var pool: SchemaPool):
        self.pool = pool^
        self.nodes = List[AvroNode]()
        self.bytes_store = List[Byte]()
        self.bytes_start = List[Int]()
        self.bytes_len = List[Int]()
        self.refs = List[Int]()
        self.root = -1

    def add_node(mut self, var n: AvroNode) -> Int:
        var id = len(self.nodes)
        self.nodes.append(n)
        return id

    def store_bytes(mut self, data: List[Byte]) -> Int:
        var start = len(self.bytes_store)
        var i = 0
        while i < len(data):
            self.bytes_store.append(data[i])
            i += 1
        self.bytes_start.append(start)
        self.bytes_len.append(len(data))
        return len(self.bytes_start) - 1

    def encode(self) -> List[Byte]:
        var enc = WireWriter()
        self._enc(enc, self.root, self.pool.root)
        return enc^.finish()

    def _enc(self, mut enc: WireWriter, nid: Int, sid: Int):
        var sid2 = self.pool.resolve(sid)
        var k = self.pool.nodes[sid2].kind
        if k == ST_NULL:
            return
        if k == ST_BOOL:
            enc.write_bool(self.nodes[nid].b)
            return
        if k == ST_INT:
            enc.write_int(Int32(self.nodes[nid].i))
            return
        if k == ST_LONG:
            enc.write_long(self.nodes[nid].i)
            return
        if k == ST_FLOAT:
            enc.write_float(Float32(from_bits=UInt32(self.nodes[nid].i)))
            return
        if k == ST_DOUBLE:
            enc.write_double(Float64(from_bits=UInt64(self.nodes[nid].i)))
            return
        if k == ST_STRING:
            enc.write_string(self.nodes[nid].s)
            return
        if k == ST_BYTES or k == ST_FIXED:
            var bi = Int(self.nodes[nid].i)
            var start = self.bytes_start[bi]
            var n = self.bytes_len[bi]
            if k == ST_BYTES:
                enc.write_long(Int64(n))
            var j = 0
            while j < n:
                enc.write_byte(self.bytes_store[start + j])
                j += 1
            return
        if k == ST_ENUM:
            enc.write_int(Int32(self.nodes[nid].i))
            return
        if k == ST_RECORD:
            var fs = self.pool.nodes[sid2].field_start
            var fc = self.pool.nodes[sid2].field_count
            var i = 0
            while i < fc:
                self._enc(enc, self.refs[self.nodes[nid].first + i], self.pool.field_type[fs + i])
                i += 1
            return
        if k == ST_ARRAY:
            var c = self.nodes[nid].count
            if c > 0:
                enc.write_block_start(Int64(c))
                var i = 0
                while i < c:
                    self._enc(enc, self.refs[self.nodes[nid].first + i], self.pool.nodes[sid2].item_id)
                    i += 1
            enc.write_block_end()
            return
        if k == ST_MAP:
            var c = self.nodes[nid].count
            if c > 0:
                enc.write_block_start(Int64(c))
                var i = 0
                while i < c:
                    var key_id = self.refs[self.nodes[nid].first + i * 2]
                    var val_id = self.refs[self.nodes[nid].first + i * 2 + 1]
                    enc.write_string(self.nodes[key_id].s)
                    self._enc(enc, val_id, self.pool.nodes[sid2].value_id)
                    i += 1
            enc.write_block_end()
            return
        if k == ST_UNION:
            var idx = Int(self.nodes[nid].i)
            enc.write_long(Int64(idx))
            var bs = self.pool.nodes[sid2].branch_start
            var child = self.refs[self.nodes[nid].first]
            self._enc(enc, child, self.pool.branch_id[bs + idx])

    def decode[origin: ImmOrigin](mut self, buf: Span[Byte, origin]) raises DecodeError:
        var dec = WireReader[origin](buf)
        self.root = self._dec(dec, self.pool.root)

    def _dec[
        origin: ImmOrigin
    ](mut self, mut dec: WireReader[origin], sid: Int) raises DecodeError -> Int:
        var sid2 = self.pool.resolve(sid)
        var k = self.pool.nodes[sid2].kind
        var n = AvroNode()
        n.schema_id = sid2
        if k == ST_NULL:
            n.kind = AV_NULL
            return self.add_node(n)
        if k == ST_BOOL:
            n.kind = AV_BOOL
            n.b = dec.read_bool()
            return self.add_node(n)
        if k == ST_INT:
            n.kind = AV_INT
            n.i = Int64(dec.read_int())
            return self.add_node(n)
        if k == ST_LONG:
            n.kind = AV_LONG
            n.i = dec.read_long()
            return self.add_node(n)
        if k == ST_FLOAT:
            n.kind = AV_FLOAT
            n.i = Int64(UInt32(dec.read_float().to_bits()))
            return self.add_node(n)
        if k == ST_DOUBLE:
            n.kind = AV_DOUBLE
            n.i = Int64(dec.read_double().to_bits())
            return self.add_node(n)
        if k == ST_STRING:
            n.kind = AV_STRING
            n.s = dec.read_string()
            return self.add_node(n)
        if k == ST_BYTES:
            n.kind = AV_BYTES
            var b = dec.read_bytes()
            n.i = Int64(self.store_bytes(b))
            return self.add_node(n)
        if k == ST_FIXED:
            n.kind = AV_FIXED
            var b = dec.read_fixed(self.pool.nodes[sid2].size)
            n.i = Int64(self.store_bytes(b))
            return self.add_node(n)
        if k == ST_ENUM:
            n.kind = AV_ENUM
            var idx = Int(dec.read_int())
            if idx < 0 or idx >= self.pool.nodes[sid2].symbol_count:
                raise DecodeError(DecodeError.KIND_BAD_ENUM, dec.position())
            n.i = Int64(idx)
            return self.add_node(n)
        if k == ST_RECORD:
            n.kind = AV_RECORD
            var first = len(self.refs)
            var fs = self.pool.nodes[sid2].field_start
            var fc = self.pool.nodes[sid2].field_count
            var i = 0
            while i < fc:
                var cid = self._dec(dec, self.pool.field_type[fs + i])
                self.refs.append(cid)
                i += 1
            n.first = first
            n.count = fc
            return self.add_node(n)
        if k == ST_ARRAY:
            n.kind = AV_ARRAY
            var first = len(self.refs)
            var total = 0
            while True:
                var count, _hint = dec.read_block_count()
                if count == 0:
                    break
                var j = Int64(0)
                while j < count:
                    var cid = self._dec(dec, self.pool.nodes[sid2].item_id)
                    self.refs.append(cid)
                    total += 1
                    j += 1
            n.first = first
            n.count = total
            return self.add_node(n)
        if k == ST_MAP:
            n.kind = AV_MAP
            var first = len(self.refs)
            var total = 0
            while True:
                var count, _hint = dec.read_block_count()
                if count == 0:
                    break
                var j = Int64(0)
                while j < count:
                    var kn = AvroNode()
                    kn.kind = AV_STRING
                    kn.s = dec.read_string()
                    var kid = self.add_node(kn)
                    var vid = self._dec(dec, self.pool.nodes[sid2].value_id)
                    self.refs.append(kid)
                    self.refs.append(vid)
                    total += 1
                    j += 1
            n.first = first
            n.count = total
            return self.add_node(n)
        if k == ST_UNION:
            n.kind = AV_UNION
            var idx = dec.read_long()
            if idx < 0 or idx >= Int64(self.pool.nodes[sid2].branch_count):
                raise DecodeError(DecodeError.KIND_BAD_UNION, dec.position())
            n.i = idx
            var bid = self.pool.branch_id[self.pool.nodes[sid2].branch_start + Int(idx)]
            var cid = self._dec(dec, bid)
            n.first = len(self.refs)
            self.refs.append(cid)
            n.count = 1
            return self.add_node(n)
        raise DecodeError(DecodeError.KIND_SCHEMA, dec.position())

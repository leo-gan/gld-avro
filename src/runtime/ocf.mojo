from std.collections import List, Optional, Span

from deflate.deflate import deflate_raw
from deflate.inflate import inflate_raw
from runtime.datum import AvroDatum, convert_to, encode
from runtime.error import DecodeError
from runtime.generic import GenericDatum
from schema.model import SchemaPool
from schema.parse_avsc import parse_avsc
from wire.reader import WireReader
from wire.writer import WireWriter


def write_ocf(schema_json: String, objects: List[List[Byte]], codec: Int) -> List[Byte]:
    """Write an OCF. codec 0 is null, codec 1 is deflate. One object per block."""
    var enc = WireWriter()
    enc.write_byte(Byte(0x4F))
    enc.write_byte(Byte(0x62))
    enc.write_byte(Byte(0x6A))
    enc.write_byte(Byte(0x01))
    # metadata map: avro.schema and maybe avro.codec
    var entries = 1
    if codec == 1:
        entries = 2
    enc.write_long(Int64(entries))
    enc.write_string(String("avro.schema"))
    enc.write_string(schema_json)
    if codec == 1:
        enc.write_string(String("avro.codec"))
        enc.write_string(String("deflate"))
    enc.write_block_end()
    var sync = List[Byte]()
    var i = 0
    while i < 16:
        sync.append(Byte(i + 1))
        i += 1
    i = 0
    while i < 16:
        enc.write_byte(sync[i])
        i += 1
    var oi = 0
    while oi < len(objects):
        var raw = objects[oi].copy()
        var payload = raw.copy()
        if codec == 1:
            payload = deflate_raw(raw)
        enc.write_long(1)
        enc.write_long(Int64(len(payload)))
        var p = 0
        while p < len(payload):
            enc.write_byte(payload[p])
            p += 1
        var s = 0
        while s < 16:
            enc.write_byte(sync[s])
            s += 1
        oi += 1
    return enc^.finish()


def read_ocf_generic[origin: ImmOrigin](buf: Span[Byte, origin]) raises DecodeError -> List[GenericDatum]:
    var dec = WireReader[origin](buf)
    if dec.remaining() < 4:
        raise DecodeError(DecodeError.KIND_OCF, 0)
    if Int(buf[0]) != 0x4F or Int(buf[1]) != 0x62 or Int(buf[2]) != 0x6A or Int(buf[3]) != 0x01:
        raise DecodeError(DecodeError.KIND_OCF, 0)
    dec.pos = 4
    var schema_json = String()
    var codec = 0
    while True:
        var count, _h = dec.read_block_count()
        if count == 0:
            break
        var j = Int64(0)
        while j < count:
            var key = dec.read_string()
            var val = dec.read_string()
            if key == "avro.schema":
                schema_json = val
            if key == "avro.codec":
                if val == "deflate":
                    codec = 1
            j += 1
    var sync = dec.read_fixed(16)
    var pool: SchemaPool
    try:
        pool = parse_avsc(schema_json)
    except _:
        raise DecodeError(DecodeError.KIND_OCF, dec.position())
    var out = List[GenericDatum]()
    while dec.remaining() > 0:
        var count = dec.read_long()
        var size = dec.read_long()
        var payload = dec.read_fixed(Int(size))
        if codec == 1:
            payload = inflate_raw(payload)
        var k = Int64(0)
        var off = 0
        while k < count:
            var p2: SchemaPool
            try:
                p2 = parse_avsc(schema_json)
            except _:
                raise DecodeError(DecodeError.KIND_OCF, dec.position())
            var g = GenericDatum(p2^)
            # decode one object from remaining payload — use a subslice
            var inner = WireReader(payload)
            inner.pos = off
            g.root = g._dec(inner, g.pool.root)
            off = inner.pos
            out.append(g^)
            k += 1
        _ = dec.read_fixed(16)
    return out^


def read_ocf[
    T: AvroDatum, origin: ImmOrigin
](buf: Span[Byte, origin]) raises DecodeError -> List[T]:
    var items = read_ocf_generic(buf)
    var out = List[T]()
    var i = 0
    while i < len(items):
        out.append(convert_to[T](items[i]))
        i += 1
    return out^


struct OcfWriter(Movable):
    var schema_json: String
    var codec: Int
    var objects: List[List[Byte]]

    def __init__(out self, schema: SchemaPool, root: Int, codec: Int):
        self.schema_json = schema.original_json
        self.codec = codec
        self.objects = List[List[Byte]]()
        _ = root

    def append[T: AvroDatum](mut self, value: T):
        self.objects.append(encode(value))

    def append_generic(mut self, value: GenericDatum):
        self.objects.append(value.encode())

    def finish(mut self) -> List[Byte]:
        return write_ocf(self.schema_json, self.objects^, self.codec)


struct OcfReader(Movable):
    var writer_schema: SchemaPool
    var codec: Int
    var sync: List[Byte]
    var payload: List[Byte]
    var pos: Int

    def __init__(out self, var writer_schema: SchemaPool, codec: Int, var sync: List[Byte]):
        self.writer_schema = writer_schema^
        self.codec = codec
        self.sync = sync^
        self.payload = List[Byte]()
        self.pos = 0

    def read_next_generic(
        mut self, var reader_schema: SchemaPool
    ) raises DecodeError -> Optional[GenericDatum]:
        _ = reader_schema^
        if self.pos >= len(self.payload):
            return Optional[GenericDatum](None)
        self.pos = len(self.payload)
        return Optional[GenericDatum](None)

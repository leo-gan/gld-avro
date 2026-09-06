from std.collections import List, Optional, Span
from avro import AvroDatum, DecodeError, WireReader, WireWriter


struct Message(Copyable, Movable, Defaultable, Deinitable, AvroDatum):
    var f_bool: Bool
    var f_int32: Int32
    var f_int64: Int64
    var f_float64: Float64
    var f_string: String
    var f_bool_2: Bool
    var f_int32_2: Int32
    var f_string_2: String

    def __init__(out self):
        self.f_bool = False
        self.f_int32 = Int32(0)
        self.f_int64 = Int64(0)
        self.f_float64 = 0.0
        self.f_string = String()
        self.f_bool_2 = False
        self.f_int32_2 = Int32(0)
        self.f_string_2 = String()

    def schema_json(self) -> String:
        return String("""{
  "type": "record",
  "name": "Message",
  "namespace": "benchmark.v2",
  "fields": [
    {"name": "f_bool", "type": "boolean", "default": false},
    {"name": "f_int32", "type": "int", "default": 0},
    {"name": "f_int64", "type": "long", "default": 0},
    {"name": "f_float64", "type": "double", "default": 0},
    {"name": "f_string", "type": "string", "default": ""},
    {"name": "f_bool_2", "type": "boolean", "default": false},
    {"name": "f_int32_2", "type": "int", "default": 0},
    {"name": "f_string_2", "type": "string", "default": ""}
  ]
}
""")

    def encoded_len(self) -> Int:
        return 64

    def encode_to(self, mut enc: WireWriter):
        enc.write_bool(self.f_bool)
        enc.write_int(self.f_int32)
        enc.write_long(self.f_int64)
        enc.write_double(self.f_float64)
        enc.write_string(self.f_string)
        enc.write_bool(self.f_bool_2)
        enc.write_int(self.f_int32_2)
        enc.write_string(self.f_string_2)

    def decode_from[origin: ImmOrigin](mut self, mut dec: WireReader[origin]) raises DecodeError:
        self.f_bool = dec.read_bool()
        self.f_int32 = dec.read_int()
        self.f_int64 = dec.read_long()
        self.f_float64 = dec.read_double()
        self.f_string = dec.read_string()
        self.f_bool_2 = dec.read_bool()
        self.f_int32_2 = dec.read_int()
        self.f_string_2 = dec.read_string()

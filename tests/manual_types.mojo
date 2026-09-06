from std.collections import List, Span

from runtime.datum import AvroDatum, decode, encode
from runtime.error import DecodeError
from wire.reader import WireReader
from wire.size import string_len, zigzag_varint_len_i32, zigzag_varint_len_i64
from wire.writer import WireWriter


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
        self.f_int32 = 0
        self.f_int64 = 0
        self.f_float64 = 0.0
        self.f_string = String()
        self.f_bool_2 = False
        self.f_int32_2 = 0
        self.f_string_2 = String()

    def __init__(
        out self,
        f_bool: Bool,
        f_int32: Int32,
        f_int64: Int64,
        f_float64: Float64,
        f_string: String,
        f_bool_2: Bool,
        f_int32_2: Int32,
        f_string_2: String,
    ):
        self.f_bool = f_bool
        self.f_int32 = f_int32
        self.f_int64 = f_int64
        self.f_float64 = f_float64
        self.f_string = f_string
        self.f_bool_2 = f_bool_2
        self.f_int32_2 = f_int32_2
        self.f_string_2 = f_string_2

    def schema_json(self) -> String:
        return String(
            '{"type":"record","name":"Message","namespace":"benchmark.v2","fields":[{"name":"f_bool","type":"boolean"},{"name":"f_int32","type":"int"},{"name":"f_int64","type":"long"},{"name":"f_float64","type":"double"},{"name":"f_string","type":"string"},{"name":"f_bool_2","type":"boolean"},{"name":"f_int32_2","type":"int"},{"name":"f_string_2","type":"string"}]}'
        )

    def encoded_len(self) -> Int:
        var n = 1
        n += zigzag_varint_len_i32(self.f_int32)
        n += zigzag_varint_len_i64(self.f_int64)
        n += 8
        n += string_len(self.f_string.byte_length())
        n += 1
        n += zigzag_varint_len_i32(self.f_int32_2)
        n += string_len(self.f_string_2.byte_length())
        return n

    def encode_to(self, mut enc: WireWriter):
        enc.write_bool(self.f_bool)
        enc.write_int(self.f_int32)
        enc.write_long(self.f_int64)
        enc.write_double(self.f_float64)
        enc.write_string(self.f_string)
        enc.write_bool(self.f_bool_2)
        enc.write_int(self.f_int32_2)
        enc.write_string(self.f_string_2)

    def decode_from[
        origin: ImmOrigin
    ](mut self, mut dec: WireReader[origin]) raises DecodeError:
        self.f_bool = dec.read_bool()
        self.f_int32 = dec.read_int()
        self.f_int64 = dec.read_long()
        self.f_float64 = dec.read_double()
        self.f_string = dec.read_string()
        self.f_bool_2 = dec.read_bool()
        self.f_int32_2 = dec.read_int()
        self.f_string_2 = dec.read_string()

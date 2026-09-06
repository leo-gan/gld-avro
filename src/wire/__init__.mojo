from wire.reader import WireReader
from wire.size import bytes_len, string_len, zigzag_varint_len_i32, zigzag_varint_len_i64
from wire.varint import decode_varint, encode_varint, varint_len
from wire.writer import WireWriter
from wire.zigzag import (
    zigzag_decode_i32,
    zigzag_decode_i64,
    zigzag_encode_i32,
    zigzag_encode_i64,
)

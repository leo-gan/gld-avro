from std.collections import List
from std.testing import TestSuite, assert_equal, assert_raises

from avro import DecodeError
from bytes_util import bytes_of, hex_of
from wire.varint import decode_varint, encode_varint, varint_len
from wire.zigzag import (
    zigzag_decode_i32,
    zigzag_decode_i64,
    zigzag_encode_i32,
    zigzag_encode_i64,
)
from wire.writer import WireWriter
from wire.reader import WireReader


def _expect(value: UInt64, want: List[Byte]) raises:
    var got = encode_varint(value)
    assert_equal(len(got), len(want), msg=hex_of(got))
    for i in range(len(want)):
        assert_equal(Int(got[i]), Int(want[i]), msg=hex_of(got))
    assert_equal(varint_len(value), len(want))
    var decoded = decode_varint(got)
    assert_equal(decoded, value)


def test_unsigned_varints() raises:
    _expect(0, bytes_of(0x00))
    _expect(1, bytes_of(0x01))
    _expect(127, bytes_of(0x7F))
    _expect(128, bytes_of(0x80, 0x01))
    _expect(300, bytes_of(0xAC, 0x02))


def test_zigzag_int() raises:
    assert_equal(zigzag_encode_i32(Int32(0)), UInt32(0))
    assert_equal(zigzag_encode_i32(Int32(-1)), UInt32(1))
    assert_equal(zigzag_encode_i32(Int32(1)), UInt32(2))
    assert_equal(zigzag_encode_i32(Int32(-2)), UInt32(3))
    assert_equal(zigzag_decode_i32(UInt32(1)), Int32(-1))
    assert_equal(zigzag_decode_i64(UInt64(1)), Int64(-1))


def test_avro_int_minus_one() raises:
    # Avro int -1 is zigzag 1, one byte 0x01 (not protobuf's ten 0xff).
    var enc = WireWriter()
    enc.write_int(Int32(-1))
    var buf = enc^.finish()
    assert_equal(len(buf), 1)
    assert_equal(Int(buf[0]), 0x01)
    var dec = WireReader(buf)
    assert_equal(dec.read_int(), Int32(-1))


def test_avro_int_150() raises:
    # zigzag(150) = 300 -> ac 02
    var enc = WireWriter()
    enc.write_int(Int32(150))
    var buf = enc^.finish()
    assert_equal(len(buf), 2)
    assert_equal(Int(buf[0]), 0xAC)
    assert_equal(Int(buf[1]), 0x02)
    var dec = WireReader(buf)
    assert_equal(dec.read_int(), Int32(150))


def test_truncated() raises:
    var buf = bytes_of(0x80)
    with assert_raises(contains="kind=1"):
        _ = decode_varint(buf)


def test_overlong_rejected() raises:
    var buf = List[Byte]()
    for _ in range(9):
        buf.append(Byte(0x80))
    buf.append(Byte(0x02))
    with assert_raises(contains="kind=2"):
        _ = decode_varint(buf)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

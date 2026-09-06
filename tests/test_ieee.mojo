from std.testing import TestSuite, assert_equal, assert_true

from wire.reader import WireReader
from wire.writer import WireWriter


def test_float_roundtrip() raises:
    var enc = WireWriter()
    enc.write_float(Float32(1.5))
    var buf = enc^.finish()
    assert_equal(len(buf), 4)
    var dec = WireReader(buf)
    var got = dec.read_float()
    assert_true(got == Float32(1.5))


def test_double_roundtrip() raises:
    var enc = WireWriter()
    enc.write_double(1.5)
    var buf = enc^.finish()
    assert_equal(len(buf), 8)
    var dec = WireReader(buf)
    var got = dec.read_double()
    assert_true(got == 1.5)


def test_string_roundtrip() raises:
    var enc = WireWriter()
    enc.write_string(String("hi"))
    var buf = enc^.finish()
    var dec = WireReader(buf)
    assert_equal(dec.read_string(), String("hi"))


def test_bool_roundtrip() raises:
    var enc = WireWriter()
    enc.write_bool(False)
    enc.write_bool(True)
    var buf = enc^.finish()
    var dec = WireReader(buf)
    assert_true(not dec.read_bool())
    assert_true(dec.read_bool())


def test_array_blocks() raises:
    var enc = WireWriter()
    enc.write_block_start(2)
    enc.write_long(1)
    enc.write_long(2)
    enc.write_block_end()
    var buf = enc^.finish()
    var dec = WireReader(buf)
    var count, hint = dec.read_block_count()
    assert_equal(count, Int64(2))
    assert_equal(hint, Int64(-1))
    assert_equal(dec.read_long(), Int64(1))
    assert_equal(dec.read_long(), Int64(2))
    var end, _h = dec.read_block_count()
    assert_equal(end, Int64(0))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

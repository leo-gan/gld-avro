from std.testing import TestSuite, assert_equal

from deflate.deflate import deflate_raw
from deflate.inflate import inflate_raw


def _bytes(*values: Int) -> List[Byte]:
    var o = List[Byte]()
    var i = 0
    while i < len(values):
        o.append(Byte(values[i] & 0xFF))
        i += 1
    return o^


def test_stored_roundtrip() raises:
    var src = _bytes(1, 2, 3)
    var z = deflate_raw(src)
    var out = inflate_raw(z)
    assert_equal(len(out), 3)
    assert_equal(Int(out[0]), 1)


def test_python_abc() raises:
    var z = _bytes(0x4B, 0x4C, 0x4A, 0x4E, 0x44, 0x42, 0x00)
    var out = inflate_raw(z)
    assert_equal(len(out), 15)


def test_python_hello() raises:
    # testdata/golden/deflate/hello.deflate from zlib.compressobj(wbits=-15)
    var z = _bytes(0xCB, 0x48, 0xCD, 0xC9, 0xC9, 0x07, 0x00)
    var out = inflate_raw(z)
    assert_equal(len(out), 5)
    assert_equal(Int(out[0]), 104)  # h
    assert_equal(Int(out[4]), 111)  # o


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

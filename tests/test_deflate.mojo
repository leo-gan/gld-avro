from std.testing import TestSuite, assert_equal

from deflate.deflate import deflate_raw
from deflate.inflate import inflate_raw


def test_stored_roundtrip() raises:
    var src = List[Byte]()
    src.append(Byte(1))
    src.append(Byte(2))
    src.append(Byte(3))
    var z = deflate_raw(src)
    var out = inflate_raw(z)
    assert_equal(len(out), 3)
    assert_equal(Int(out[0]), 1)
    assert_equal(Int(out[2]), 3)


def test_empty() raises:
    var src = List[Byte]()
    var z = deflate_raw(src)
    var out = inflate_raw(z)
    assert_equal(len(out), 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

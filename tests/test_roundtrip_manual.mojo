from std.testing import TestSuite, assert_equal, assert_true

from manual_types import Message
from runtime.datum import decode, encode


def test_message_roundtrip() raises:
    var m = Message(
        True,
        Int32(150),
        Int64(1),
        1.5,
        String("hi"),
        False,
        Int32(7),
        String("x"),
    )
    var buf = encode(m)
    var m2 = decode[Message](buf)
    assert_true(m2.f_bool)
    assert_equal(m2.f_int32, Int32(150))
    assert_equal(m2.f_int64, Int64(1))
    assert_true(m2.f_float64 == 1.5)
    assert_equal(m2.f_string, String("hi"))
    assert_true(not m2.f_bool_2)
    assert_equal(m2.f_int32_2, Int32(7))
    assert_equal(m2.f_string_2, String("x"))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

from std.testing import TestSuite, assert_equal, assert_true

from Message import Message
from avro import decode, encode


def test_generated_message_roundtrip() raises:
    var m = Message()
    m.f_bool = True
    m.f_int32 = 150
    m.f_int64 = 1
    m.f_float64 = 1.5
    m.f_string = String("hi")
    var buf = encode(m)
    var m2 = decode[Message](buf)
    assert_true(m2.f_bool)
    assert_equal(m2.f_int32, Int32(150))
    assert_equal(m2.f_string, String("hi"))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

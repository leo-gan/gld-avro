from std.testing import TestSuite, assert_equal, assert_true

from manual_types import Message
from runtime.datum import decode, encode
from runtime.soe import decode_single_object, encode_single_object, soe_fingerprint


def test_soe_roundtrip() raises:
    var m = Message()
    m.f_int32 = 150
    var buf = encode_single_object(m)
    assert_equal(Int(buf[0]), 0xC3)
    assert_equal(Int(buf[1]), 0x01)
    var fp = soe_fingerprint(buf)
    assert_true(fp != 0)
    var m2 = decode_single_object[Message](buf)
    assert_equal(m2.f_int32, Int32(150))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

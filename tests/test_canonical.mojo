from std.testing import TestSuite, assert_equal, assert_true

from schema.canonical import canonical_form
from schema.fingerprint import EMPTY64, crc64_avro
from schema.parse_avsc import parse_avsc


def test_int_pcf() raises:
    var p = parse_avsc(String('"int"'))
    assert_equal(canonical_form(p), String("int"))


def test_record_pcf_order() raises:
    var p = parse_avsc(
        String('{"doc":"x","type":"record","name":"M","fields":[{"name":"a","type":"int"}]}')
    )
    var c = canonical_form(p)
    assert_true(c == String('{"name":"M","type":"record","fields":[{"name":"a","type":int}]}'))


def test_longlist_pcf_no_loop() raises:
    var f = open("testdata/avsc/longlist.avsc", "r")
    var text = String(f.read())
    f.close()
    var p = parse_avsc(text)
    var c = canonical_form(p)
    assert_true(c.byte_length() > 10)
    # later visit of LongList is the quoted fullname, not another object
    var fp = crc64_avro(c)
    assert_true(fp != EMPTY64)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

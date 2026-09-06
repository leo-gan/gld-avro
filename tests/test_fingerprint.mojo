from std.testing import TestSuite, assert_equal, assert_true

from schema.fingerprint import EMPTY64, crc64_avro


def test_empty() raises:
    assert_equal(crc64_avro(String()), EMPTY64)


def test_null_schema() raises:
    # PCF of the primitive null schema is the four bytes n u l l
    var fp = crc64_avro(String("null"))
    assert_true(fp != EMPTY64)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

from std.testing import TestSuite, assert_true

from schema.parse_avsc import parse_avsc


def test_mutual_names() raises:
    var f = open("testdata/avsc/mutual_ab.avsc", "r")
    var text = String(f.read())
    f.close()
    var p = parse_avsc(text)
    assert_true(p.find_name(String("A")) >= 0)
    assert_true(p.find_name(String("B")) >= 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

from std.testing import TestSuite, assert_equal, assert_true

from schema.model import ST_RECORD
from schema.parse_avdl import parse_avdl


def test_parse_avdl_record() raises:
    var f = open("testdata/avdl/message.avdl", "r")
    var text = String(f.read())
    f.close()
    var p = parse_avdl(text)
    assert_true(p.root >= 0)
    assert_equal(p.kind_of(p.root), ST_RECORD)
    assert_true(p.find_name(String("benchmark.v2.Message")) >= 0)
    assert_equal(p.nodes[p.root].field_count, 5)
    assert_equal(p.field_name[p.nodes[p.root].field_start], String("f_bool"))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

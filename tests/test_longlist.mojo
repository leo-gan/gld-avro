from std.testing import TestSuite, assert_equal, assert_true

from schema.model import ST_RECORD, ST_UNION
from schema.parse_avsc import parse_avsc


def test_longlist_schema() raises:
    var f = open("testdata/avsc/longlist.avsc", "r")
    var text = String(f.read())
    f.close()
    var p = parse_avsc(text)
    assert_equal(p.kind_of(p.root), ST_RECORD)
    var fs = p.nodes[p.root].field_start
    assert_equal(p.field_name[fs], String("value"))
    assert_equal(p.kind_of(p.field_type[fs + 1]), ST_UNION)
    assert_true(p.find_name(String("LongList")) >= 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

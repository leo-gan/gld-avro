from std.testing import TestSuite, assert_true

from schema.model import ST_RECORD
from schema.parse_avpr import parse_avpr


def test_parse_avpr_types() raises:
    var f = open("testdata/avpr/bench.avpr", "r")
    var text = String(f.read())
    f.close()
    var p = parse_avpr(text)
    assert_true(p.kind_of(p.root) == ST_RECORD)
    assert_true(p.find_name(String("benchmark.v2.Message")) >= 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

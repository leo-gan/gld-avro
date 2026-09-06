from std.testing import TestSuite, assert_equal, assert_true

from schema.model import ST_INT, ST_RECORD, ST_STRING, ST_UNION
from schema.parse_avsc import parse_avsc


def test_record_nullable() raises:
    var text = String(
        '{"type":"record","name":"M","fields":[{"name":"s","type":["null","string"],"default":null}]}'
    )
    var p = parse_avsc(text)
    assert_equal(p.kind_of(p.root), ST_RECORD)
    var fs = p.nodes[p.root].field_start
    assert_equal(p.field_name[fs], String("s"))
    var uid = p.field_type[fs]
    assert_equal(p.kind_of(uid), ST_UNION)
    assert_equal(p.nodes[p.resolve(uid)].branch_count, 2)


def test_nested_named() raises:
    var text = String(
        '{"type":"record","name":"Doc","namespace":"benchmark.v2","fields":[{"name":"meta","type":{"type":"record","name":"Meta","fields":[{"name":"k","type":"int"}]}}]}'
    )
    var p = parse_avsc(text)
    assert_true(p.find_name(String("benchmark.v2.Doc")) >= 0)
    assert_true(p.find_name(String("benchmark.v2.Meta")) >= 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

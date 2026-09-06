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


def test_longlist() raises:
    var f = open("testdata/avsc/longlist.avsc", "r")
    var text = String(f.read())
    f.close()
    var p = parse_avsc(text)
    assert_equal(p.kind_of(p.root), ST_RECORD)
    assert_true(p.find_name(String("LongList")) >= 0)
    var fs = p.nodes[p.root].field_start
    assert_equal(p.field_name[fs + 1], String("next"))
    assert_equal(p.kind_of(p.field_type[fs + 1]), ST_UNION)


def test_mutual_ab() raises:
    var f = open("testdata/avsc/mutual_ab.avsc", "r")
    var text = String(f.read())
    f.close()
    var p = parse_avsc(text)
    assert_true(p.find_name(String("A")) >= 0)
    assert_true(p.find_name(String("B")) >= 0)


def test_two_array_union_rejected() raises:
    var text = String(
        '{"type":"record","name":"Bad","fields":[{"name":"x","type":[{"type":"array","items":"int"},{"type":"array","items":"string"}]}]}'
    )
    var threw = False
    try:
        _ = parse_avsc(text)
    except _:
        threw = True
    assert_true(threw)


def test_union_default_mismatch() raises:
    var text = String(
        '{"type":"record","name":"D","fields":[{"name":"s","type":["null","string"],"default":"hi"}]}'
    )
    var threw = False
    try:
        _ = parse_avsc(text)
    except _:
        threw = True
    assert_true(threw)


def test_nested_named() raises:
    var text = String(
        '{"type":"record","name":"Doc","namespace":"benchmark.v2","fields":[{"name":"meta","type":{"type":"record","name":"Meta","fields":[{"name":"k","type":"int"}]}}]}'
    )
    var p = parse_avsc(text)
    assert_true(p.find_name(String("benchmark.v2.Doc")) >= 0)
    assert_true(p.find_name(String("benchmark.v2.Meta")) >= 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

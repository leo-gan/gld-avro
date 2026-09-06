from std.testing import TestSuite, assert_equal, assert_true

from schema.model import ST_RECORD, ST_UNION
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


def test_parse_avdl_longlist_nullable() raises:
    var f = open("testdata/avdl/longlist.avdl", "r")
    var text = String(f.read())
    f.close()
    var p = parse_avdl(text)
    assert_true(p.find_name(String("LongList")) >= 0)
    var fs = p.nodes[p.root].field_start
    assert_equal(p.field_name[fs + 1], String("next"))
    assert_equal(p.kind_of(p.field_type[fs + 1]), ST_UNION)


def test_parse_avdl_enum_and_fixed() raises:
    var f = open("testdata/avdl/enum_fixed.avdl", "r")
    var text = String(f.read())
    f.close()
    var p = parse_avdl(text)
    assert_true(p.find_name(String("Color")) >= 0)
    assert_true(p.find_name(String("MD5")) >= 0)
    assert_true(p.find_name(String("Tagged")) >= 0)


def test_parse_avdl_import_schema() raises:
    var f = open("testdata/avdl/uses_leaf.avdl", "r")
    var text = String(f.read())
    f.close()
    var p = parse_avdl(text, String("testdata/avdl/uses_leaf.avdl"))
    assert_true(p.find_name(String("Leaf")) >= 0)
    assert_true(p.find_name(String("Wrap")) >= 0)


def test_avdl_rejected_by_parse_avpr() raises:
    from schema.parse_avpr import parse_avpr

    var threw = False
    try:
        _ = parse_avpr(String("@namespace(\"n\") protocol P { record R { int x; } }"))
    except _:
        threw = True
    assert_true(threw)


def test_avpr_rejected_by_parse_avdl() raises:
    var f = open("testdata/avpr/bench.avpr", "r")
    var text = String(f.read())
    f.close()
    var threw = False
    try:
        _ = parse_avdl(text)
    except _:
        threw = True
    assert_true(threw)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

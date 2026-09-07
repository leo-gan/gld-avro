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


def test_idl_error_and_literals() raises:
    var f = open("testdata/avdl/error_lit.avdl", "r")
    var text = String(f.read())
    f.close()
    var p = parse_avdl(text)
    var boom = p.find_name(String("Boom"))
    assert_true(boom >= 0)
    assert_true(p.nodes[boom].is_error)
    var hid = p.find_name(String("Holder"))
    assert_true(hid >= 0)
    var fs = p.nodes[hid].field_start
    assert_equal(p.field_name[fs], String("xs"))
    assert_equal(p.field_default[fs], String("[1,2]"))
    assert_equal(p.field_name[fs + 1], String("m"))
    assert_equal(p.field_default[fs + 1], String("{\"k\":\"v\"}"))
    assert_equal(p.field_name[fs + 2], String("err"))
    assert_equal(p.field_default[fs + 2], String("{\"msg\":\"x\"}"))


def test_idl_logical_annotation() raises:
    var f = open("testdata/avdl/logical.avdl", "r")
    var text = String(f.read())
    f.close()
    var p = parse_avdl(text)
    var rid = p.find_name(String("Dated"))
    assert_true(rid >= 0)
    var fs = p.nodes[rid].field_start
    var dty = p.resolve(p.field_type[fs])
    assert_equal(p.nodes[dty].logical_type, String("date"))
    var idty = p.resolve(p.field_type[fs + 1])
    assert_equal(p.nodes[idty].logical_type, String("uuid"))
    var tsty = p.resolve(p.field_type[fs + 2])
    assert_equal(p.nodes[tsty].logical_type, String("timestamp-millis"))


def test_file_import_resolver() raises:
    from schema.parse_avdl import FileImportResolver

    var f = open("testdata/avdl/uses_leaf.avdl", "r")
    var text = String(f.read())
    f.close()
    var r = FileImportResolver()
    var p = parse_avdl(text, String("testdata/avdl/uses_leaf.avdl"), r)
    assert_true(p.find_name(String("Leaf")) >= 0)
    assert_true(p.find_name(String("Wrap")) >= 0)


def test_parse_avdl_import_idl() raises:
    var f = open("testdata/avdl/uses_idl.avdl", "r")
    var text = String(f.read())
    f.close()
    var p = parse_avdl(text, String("testdata/avdl/uses_idl.avdl"))
    assert_true(p.find_name(String("LeafIdl")) >= 0)
    assert_true(p.find_name(String("WrapIdl")) >= 0)


def test_parse_avdl_import_protocol() raises:
    var f = open("testdata/avdl/uses_protocol.avdl", "r")
    var text = String(f.read())
    f.close()
    var p = parse_avdl(text, String("testdata/avdl/uses_protocol.avdl"))
    assert_true(p.find_name(String("benchmark.v2.Message")) >= 0)
    assert_true(p.find_name(String("Holder")) >= 0)


def test_parse_avdl_cyclic_import() raises:
    var f = open("testdata/avdl/cycle_a.avdl", "r")
    var text = String(f.read())
    f.close()
    var threw = False
    try:
        _ = parse_avdl(text, String("testdata/avdl/cycle_a.avdl"))
    except _:
        threw = True
    assert_true(threw)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

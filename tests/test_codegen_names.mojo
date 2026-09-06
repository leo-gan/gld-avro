from std.testing import TestSuite, assert_true

from codegen.emit import emit_one_record
from schema.parse_avsc import parse_avsc


def test_longlist_emits_box() raises:
    var f = open("testdata/avsc/longlist.avsc", "r")
    var text = String(f.read())
    f.close()
    var p = parse_avsc(text)
    var src = emit_one_record(p, p.root)
    assert_true(src.find("Optional[Box[LongList]]") >= 0)


def test_mutual_ab_emits_box() raises:
    var f = open("testdata/avsc/mutual_ab.avsc", "r")
    var text = String(f.read())
    f.close()
    var p = parse_avsc(text)
    var a = p.find_name(String("A"))
    var src = emit_one_record(p, a)
    assert_true(src.find("Optional[Box[B]]") >= 0)


def test_node_union_emits() raises:
    var f = open("testdata/avsc/node_union.avsc", "r")
    var text = String(f.read())
    f.close()
    var p = parse_avsc(text)
    var src = emit_one_record(p, p.root)
    assert_true(src.find("struct Node") >= 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

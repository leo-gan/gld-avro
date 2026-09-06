from std.testing import TestSuite, assert_equal, assert_true

from json.parse import parse_json
from json.value import JSON_ARRAY, JSON_BOOL, JSON_INT, JSON_OBJECT, JSON_STRING


def test_primitives() raises:
    var n = parse_json(String("null"))
    assert_equal(n.kind(n.root), 0)
    var t = parse_json(String("true"))
    assert_true(t.as_bool(t.root))
    var i = parse_json(String("-12"))
    assert_equal(i.as_int(i.root), Int64(-12))
    var s = parse_json(String('"hi"'))
    assert_equal(s.as_string(s.root), String("hi"))


def test_array_object() raises:
    var a = parse_json(String("[1, 2, 3]"))
    assert_equal(a.kind(a.root), JSON_ARRAY)
    assert_equal(a.nodes[a.root].count, 3)
    assert_equal(a.as_int(a.child(a.root, 1)), Int64(2))
    var o = parse_json(String('{"type":"record","name":"M"}'))
    assert_equal(o.kind(o.root), JSON_OBJECT)
    var t = o.find(o.root, String("type"))
    assert_true(t >= 0)
    assert_equal(o.as_string(t), String("record"))
    var nm = o.find(o.root, String("name"))
    assert_equal(o.as_string(nm), String("M"))


def test_nested() raises:
    var d = parse_json(String('{"fields":[{"name":"a","type":"int"}]}'))
    var fields = d.find(d.root, String("fields"))
    assert_equal(d.kind(fields), JSON_ARRAY)
    var f0 = d.child(fields, 0)
    var n = d.find(f0, String("name"))
    assert_equal(d.as_string(n), String("a"))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

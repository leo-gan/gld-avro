from std.testing import TestSuite, assert_equal, assert_true

from runtime.json_codec import decode_default
from schema.parse_avsc import parse_avsc


def test_default_int() raises:
    var p = parse_avsc(String('"int"'))
    var g = decode_default(String("7"), p^, p.root)
    assert_equal(g.nodes[g.root].i, Int64(7))


def test_default_bool_string_long() raises:
    var pb = parse_avsc(String('"boolean"'))
    var gb = decode_default(String("true"), pb^, pb.root)
    assert_true(gb.nodes[gb.root].b)
    var ps = parse_avsc(String('"string"'))
    var gs = decode_default(String("\"ab\""), ps^, ps.root)
    assert_equal(gs.nodes[gs.root].s, String("ab"))
    var pl = parse_avsc(String('"long"'))
    var gl = decode_default(String("99"), pl^, pl.root)
    assert_equal(gl.nodes[gl.root].i, Int64(99))


def test_default_null_union_first() raises:
    var p = parse_avsc(
        String(
            '{"type":"record","name":"R","fields":[{"name":"s","type":["null","string"],"default":null}]}'
        )
    )
    var fs = p.nodes[p.root].field_start
    var tid = p.field_type[fs]
    var g = decode_default(String("null"), p^, tid)
    assert_true(g.nodes[g.root].kind == 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

from std.testing import TestSuite, assert_equal, assert_true

from runtime.generic import GenericDatum
from runtime.json_codec import decode_json_generic, encode_json_generic
from schema.parse_avsc import parse_avsc
from wire.writer import WireWriter


def test_json_int_record() raises:
    var schema = String(
        '{"type":"record","name":"M","fields":[{"name":"x","type":"int"}]}'
    )
    var pool = parse_avsc(schema)
    var g = GenericDatum(pool^)
    var enc = WireWriter()
    enc.write_int(Int32(150))
    var buf = enc^.finish()
    g.decode(buf)
    var text = encode_json_generic(g)
    assert_true(text.find("150") >= 0)
    var p2 = parse_avsc(schema)
    var root2 = p2.root
    var g2 = decode_json_generic(text, p2^, root2)
    assert_equal(g2.nodes[g2.refs[g2.nodes[g2.root].first]].i, Int64(150))


def test_json_union_string() raises:
    var schema = String('["null","string"]')
    var pool = parse_avsc(schema)
    var g = GenericDatum(pool^)
    var enc = WireWriter()
    enc.write_long(1)
    enc.write_string(String("hi"))
    g.decode(enc^.finish())
    var text = encode_json_generic(g)
    assert_equal(text, String("{\"string\":\"hi\"}"))
    var p2 = parse_avsc(schema)
    var root2 = p2.root
    var g2 = decode_json_generic(String('{"string":"hi"}'), p2^, root2)
    assert_equal(g2.nodes[g2.refs[g2.nodes[g2.root].first]].s, String("hi"))


def test_json_union_null() raises:
    var schema = String('["null","string"]')
    var p = parse_avsc(schema)
    var root = p.root
    var g = decode_json_generic(String("null"), p^, root)
    assert_equal(g.nodes[g.root].i, Int64(0))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

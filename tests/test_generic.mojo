from std.testing import TestSuite, assert_equal

from runtime.generic import AV_INT, AV_RECORD, AvroNode, GenericDatum
from schema.parse_avsc import parse_avsc
from wire.reader import WireReader
from wire.writer import WireWriter


def test_int_field_150() raises:
    var schema = String(
        '{"type":"record","name":"M","fields":[{"name":"x","type":"int"}]}'
    )
    var pool = parse_avsc(schema)
    var g = GenericDatum(pool^)
    var rec = AvroNode()
    rec.kind = AV_RECORD
    rec.first = 0
    rec.count = 1
    var child = AvroNode()
    child.kind = AV_INT
    child.i = 150
    var cid = g.add_node(child)
    g.refs.append(cid)
    g.root = g.add_node(rec)
    var buf = g.encode()
    assert_equal(len(buf), 2)
    assert_equal(Int(buf[0]), 0xAC)
    assert_equal(Int(buf[1]), 0x02)
    var g2 = GenericDatum(parse_avsc(schema))
    g2.decode(buf)
    assert_equal(g2.nodes[g2.refs[g2.nodes[g2.root].first]].i, Int64(150))


def test_string_and_null_union() raises:
    var schema = String(
        '{"type":"record","name":"S","fields":[{"name":"s","type":["null","string"],"default":null}]}'
    )
    var pool = parse_avsc(schema)
    # None -> union index 0, no payload
    var g = GenericDatum(pool^)
    # decode bytes: 00
    var enc = WireWriter()
    enc.write_long(0)
    var buf = enc^.finish()
    g.decode(buf)
    assert_equal(g.nodes[g.refs[g.nodes[g.root].first]].i, Int64(0))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

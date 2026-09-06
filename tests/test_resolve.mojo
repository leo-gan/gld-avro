from std.testing import TestSuite, assert_equal, assert_true

from runtime.resolve import can_resolve, named_match
from schema.parse_avsc import parse_avsc


def test_unqualified_name_match() raises:
    var w = parse_avsc(
        String(
            '{"type":"record","name":"Foo","namespace":"com.a","fields":[{"name":"x","type":"int"}]}'
        )
    )
    var r = parse_avsc(
        String(
            '{"type":"record","name":"Foo","namespace":"com.b","fields":[{"name":"x","type":"int"}]}'
        )
    )
    assert_true(named_match(w, w.root, r, r.root))
    assert_true(can_resolve(w, w.root, r, r.root))


def test_reader_alias_match() raises:
    var w = parse_avsc(
        String(
            '{"type":"record","name":"Foo","fields":[{"name":"x","type":"int"}]}'
        )
    )
    var r = parse_avsc(
        String(
            '{"type":"record","name":"Bar","aliases":["Foo"],"fields":[{"name":"x","type":"int"}]}'
        )
    )
    assert_true(named_match(w, w.root, r, r.root))


def test_writer_alias_does_not_match() raises:
    var w = parse_avsc(
        String(
            '{"type":"record","name":"Foo","aliases":["Bar"],"fields":[{"name":"x","type":"int"}]}'
        )
    )
    var r = parse_avsc(
        String(
            '{"type":"record","name":"Bar","fields":[{"name":"x","type":"int"}]}'
        )
    )
    assert_true(not named_match(w, w.root, r, r.root))


def test_fixed_size_must_match() raises:
    var w = parse_avsc(String('{"type":"fixed","name":"F","size":4}'))
    var r = parse_avsc(String('{"type":"fixed","name":"F","size":8}'))
    assert_true(not can_resolve(w, w.root, r, r.root))


def test_int_promotes_to_long() raises:
    var w = parse_avsc(String('"int"'))
    var r = parse_avsc(String('"long"'))
    assert_true(can_resolve(w, w.root, r, r.root))


def test_decode_int_to_long() raises:
    from runtime.resolve import decode_resolving_generic
    from wire.writer import WireWriter

    var enc = WireWriter()
    enc.write_int(Int32(150))
    var buf = enc^.finish()
    var g = decode_resolving_generic(
        buf, parse_avsc(String('"int"')), parse_avsc(String('"long"'))
    )
    assert_true(g.nodes[g.root].i == Int64(150))


def test_compile_plan_promote() raises:
    from runtime.resolve import ACT_PROMOTE, compile_plan

    var plan = compile_plan(parse_avsc(String('"int"')), parse_avsc(String('"long"')))
    assert_true(plan.valid)
    assert_true(len(plan.actions) >= 1)
    assert_true(plan.actions[0] == ACT_PROMOTE)


def test_field_reorder_and_default() raises:
    from runtime.resolve import decode_resolving_generic
    from wire.writer import WireWriter

    var w = parse_avsc(
        String(
            '{"type":"record","name":"W","fields":[{"name":"b","type":"int"},{"name":"extra","type":"int"}]}'
        )
    )
    var r = parse_avsc(
        String(
            '{"type":"record","name":"W","fields":[{"name":"a","type":"int","default":7},{"name":"b","type":"int"}]}'
        )
    )
    var enc = WireWriter()
    enc.write_int(Int32(3))
    enc.write_int(Int32(9))
    var g = decode_resolving_generic(enc^.finish(), w^, r^)
    var rec = g.nodes[g.root]
    assert_equal(rec.count, 2)
    # reader order: a (default 7), b (writer 3)
    assert_equal(g.nodes[g.refs[rec.first]].i, Int64(7))
    assert_equal(g.nodes[g.refs[rec.first + 1]].i, Int64(3))


def test_enum_unknown_uses_default() raises:
    from runtime.resolve import decode_resolving_generic
    from wire.writer import WireWriter

    var w = parse_avsc(
        String('{"type":"enum","name":"E","symbols":["A","B","C"]}')
    )
    var r = parse_avsc(
        String('{"type":"enum","name":"E","symbols":["A","B"],"default":"A"}')
    )
    var enc = WireWriter()
    enc.write_int(Int32(2))
    var g = decode_resolving_generic(enc^.finish(), w^, r^)
    assert_equal(g.nodes[g.root].i, Int64(0))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

from std.testing import TestSuite, assert_equal, assert_true

from schema.model import ST_ENUM, ST_RECORD, ST_UNION
from schema.parse_avsc import parse_avsc


def _throws(text: String) -> Bool:
    var threw = False
    try:
        _ = parse_avsc(text)
    except _:
        threw = True
    return threw


def test_empty_union_rejected() raises:
    assert_true(
        _throws(
            String(
                '{"type":"record","name":"E","fields":[{"name":"x","type":[]}]}'
            )
        )
    )


def test_nested_union_rejected() raises:
    assert_true(
        _throws(
            String(
                '{"type":"record","name":"N","fields":[{"name":"x","type":[["null","int"],"string"]}]}'
            )
        )
    )


def test_duplicate_int_union_rejected() raises:
    assert_true(
        _throws(
            String(
                '{"type":"record","name":"D","fields":[{"name":"x","type":["int","int"]}]}'
            )
        )
    )


def test_two_named_records_in_union_ok() raises:
    var p = parse_avsc(
        String(
            '{"type":"record","name":"H","fields":[{"name":"x","type":[{"type":"record","name":"A","fields":[]},{"type":"record","name":"B","fields":[]}]}]}'
        )
    )
    assert_true(p.find_name(String("A")) >= 0)
    assert_true(p.find_name(String("B")) >= 0)


def test_illegal_record_name() raises:
    assert_true(
        _throws(
            String('{"type":"record","name":"1bad","fields":[]}')
        )
    )


def test_illegal_enum_name() raises:
    assert_true(
        _throws(
            String('{"type":"enum","name":"bad-name","symbols":["A"]}')
        )
    )


def test_inline_enum() raises:
    var p = parse_avsc(
        String(
            '{"type":"record","name":"R","fields":[{"name":"c","type":{"type":"enum","name":"Color","symbols":["RED","BLUE"]}}]}'
        )
    )
    assert_true(p.find_name(String("Color")) >= 0)
    var fs = p.nodes[p.root].field_start
    assert_equal(p.kind_of(p.field_type[fs]), ST_ENUM)


def test_type_as_array_at_root() raises:
    var p = parse_avsc(String('["null","int"]'))
    assert_equal(p.kind_of(p.root), ST_UNION)


def test_string_first_union_default_string_ok() raises:
    var p = parse_avsc(
        String(
            '{"type":"record","name":"S","fields":[{"name":"s","type":["string","null"],"default":"hi"}]}'
        )
    )
    assert_equal(p.kind_of(p.root), ST_RECORD)


def test_string_first_union_default_null_rejected() raises:
    assert_true(
        _throws(
            String(
                '{"type":"record","name":"S","fields":[{"name":"s","type":["string","null"],"default":null}]}'
            )
        )
    )


def test_unknown_name_is_stub_record() raises:
    # Forward refs become ST_RECORD stubs so LongList-style recursion works.
    var p = parse_avsc(
        String(
            '{"type":"record","name":"R","fields":[{"name":"x","type":"Later"}]}'
        )
    )
    assert_true(p.find_name(String("Later")) >= 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

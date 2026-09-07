from std.testing import TestSuite, assert_equal, assert_true

from runtime.generic import GenericDatum
from runtime.logical import (
    LT_DATE,
    LT_DECIMAL,
    LT_DURATION,
    LT_TIME_MILLIS,
    LT_TIMESTAMP_MILLIS,
    LT_UUID,
    LogicalDuration,
    civil_from_days,
    days_from_civil,
    decimal_unscaled_from_i64,
    decimal_unscaled_to_i64,
    decode_date,
    decode_decimal,
    decode_duration,
    decode_time_millis,
    decode_timestamp_millis,
    decode_uuid,
    duration_from_fixed,
    duration_to_fixed,
    encode_date,
    encode_decimal,
    encode_decimal_fixed,
    encode_duration,
    encode_time_millis,
    encode_timestamp_millis,
    encode_uuid,
    logical_kind,
    logical_underlying_ok,
    time_micros_valid,
    time_millis_valid,
    uuid_is_valid,
)
from schema.model import ST_BYTES, ST_FIXED, ST_INT, ST_LONG, ST_STRING
from schema.parse_avsc import parse_avsc
from wire.writer import WireWriter


def test_logical_kind_names() raises:
    assert_equal(logical_kind(String("decimal")), LT_DECIMAL)
    assert_equal(logical_kind(String("uuid")), LT_UUID)
    assert_equal(logical_kind(String("date")), LT_DATE)
    assert_equal(logical_kind(String("duration")), LT_DURATION)


def test_uuid_valid() raises:
    assert_true(uuid_is_valid(String("550e8400-e29b-41d4-a716-446655440000")))
    assert_true(not uuid_is_valid(String("not-a-uuid")))
    assert_true(not uuid_is_valid(String("550e8400e29b41d4a716446655440000")))


def test_date_epoch_roundtrip() raises:
    assert_equal(days_from_civil(1970, 1, 1), Int32(0))
    var d = civil_from_days(Int32(0))
    assert_equal(d.year, 1970)
    assert_equal(d.month, 1)
    assert_equal(d.day, 1)
    var d2 = civil_from_days(days_from_civil(2020, 2, 29))
    assert_equal(d2.year, 2020)
    assert_equal(d2.month, 2)
    assert_equal(d2.day, 29)


def test_time_range() raises:
    assert_true(time_millis_valid(Int32(0)))
    assert_true(time_millis_valid(Int32(86399999)))
    assert_true(not time_millis_valid(Int32(86400000)))
    assert_true(time_micros_valid(Int64(0)))
    assert_true(not time_micros_valid(Int64(-1)))


def test_decimal_unscaled_1234() raises:
    var b = decimal_unscaled_from_i64(Int64(1234))
    assert_equal(Int(b[len(b) - 1]), 0xD2)
    assert_equal(decimal_unscaled_to_i64(b), Int64(1234))
    var n = decimal_unscaled_from_i64(Int64(-1))
    assert_equal(len(n), 1)
    assert_equal(Int(n[0]), 0xFF)


def test_duration_fixed12() raises:
    var d = LogicalDuration(UInt32(1), UInt32(2), UInt32(3))
    var b = duration_to_fixed(d)
    assert_equal(len(b), 12)
    var back = duration_from_fixed(b)
    assert_equal(Int(back.months), 1)
    assert_equal(Int(back.days), 2)
    assert_equal(Int(back.millis), 3)


def test_schema_stores_logical_and_leftovers() raises:
    var p = parse_avsc(
        String(
            '{"type":"bytes","logicalType":"decimal","precision":4,"scale":2}'
        )
    )
    var id = p.resolve(p.root)
    assert_equal(p.nodes[id].logical_type, String("decimal"))
    assert_equal(p.leftover(id, String("precision")), String("4"))
    assert_equal(p.leftover(id, String("scale")), String("2"))


def test_error_type_is_record() raises:
    var p = parse_avsc(
        String('{"type":"error","name":"Boom","fields":[{"name":"msg","type":"string"}]}')
    )
    var id = p.resolve(p.root)
    assert_true(p.nodes[id].is_error)
    assert_true(p.find_name(String("Boom")) >= 0)


def test_logical_underlying_ok() raises:
    assert_true(logical_underlying_ok(ST_BYTES, 0, LT_DECIMAL))
    assert_true(logical_underlying_ok(ST_FIXED, 16, LT_DECIMAL))
    assert_true(logical_underlying_ok(ST_STRING, 0, LT_UUID))
    assert_true(logical_underlying_ok(ST_INT, 0, LT_DATE))
    assert_true(logical_underlying_ok(ST_INT, 0, LT_TIME_MILLIS))
    assert_true(logical_underlying_ok(ST_LONG, 0, LT_TIMESTAMP_MILLIS))
    assert_true(logical_underlying_ok(ST_FIXED, 12, LT_DURATION))
    assert_true(not logical_underlying_ok(ST_INT, 0, LT_UUID))
    assert_true(not logical_underlying_ok(ST_FIXED, 8, LT_DURATION))


def test_date_codec_roundtrip() raises:
    var buf = encode_date(2020, 2, 29)
    var d = decode_date(buf)
    assert_equal(d.year, 2020)
    assert_equal(d.month, 2)
    assert_equal(d.day, 29)


def test_uuid_codec_roundtrip() raises:
    var s = String("550e8400-e29b-41d4-a716-446655440000")
    var buf = encode_uuid(s)
    assert_equal(decode_uuid(buf), s)


def test_uuid_codec_rejects_bad() raises:
    var threw = False
    try:
        _ = encode_uuid(String("not-a-uuid"))
    except _:
        threw = True
    assert_true(threw)


def test_time_and_timestamp_codecs() raises:
    var tbuf = encode_time_millis(Int32(1234))
    assert_equal(decode_time_millis(tbuf), Int32(1234))
    var threw = False
    try:
        _ = encode_time_millis(Int32(86400000))
    except _:
        threw = True
    assert_true(threw)
    var sbuf = encode_timestamp_millis(Int64(1_600_000_000_000))
    assert_equal(decode_timestamp_millis(sbuf), Int64(1_600_000_000_000))


def test_duration_codec_roundtrip() raises:
    var d = LogicalDuration(UInt32(1), UInt32(2), UInt32(3))
    var buf = encode_duration(d)
    assert_equal(len(buf), 12)
    var back = decode_duration(buf)
    assert_equal(Int(back.months), 1)
    assert_equal(Int(back.days), 2)
    assert_equal(Int(back.millis), 3)


def test_decimal_codec_roundtrip() raises:
    var buf = encode_decimal(Int64(-1234))
    assert_equal(decode_decimal(buf), Int64(-1234))
    var fx = encode_decimal_fixed(Int64(1234), 4)
    assert_equal(len(fx), 4)


def test_duration_schema_and_leftovers() raises:
    var p = parse_avsc(
        String(
            '{"type":"fixed","name":"Dur","size":12,"logicalType":"duration"}'
        )
    )
    var id = p.resolve(p.root)
    assert_equal(p.nodes[id].logical_type, String("duration"))
    assert_equal(p.nodes[id].size, 12)
    var p2 = parse_avsc(
        String(
            '{"type":"fixed","name":"Dec","size":8,"logicalType":"decimal","precision":10,"scale":2}'
        )
    )
    var id2 = p2.resolve(p2.root)
    assert_equal(p2.nodes[id2].logical_type, String("decimal"))
    assert_equal(p2.leftover(id2, String("precision")), String("10"))
    assert_equal(p2.leftover(id2, String("scale")), String("2"))


def test_generic_rejects_bad_uuid() raises:
    var schema = String('{"type":"string","logicalType":"uuid"}')
    var g = GenericDatum(parse_avsc(schema))
    var good = encode_uuid(String("550e8400-e29b-41d4-a716-446655440000"))
    g.decode(good)
    assert_equal(g.as_string(), String("550e8400-e29b-41d4-a716-446655440000"))
    var bad = GenericDatum(parse_avsc(schema))
    var enc = WireWriter()
    enc.write_string(String("not-id"))
    var threw = False
    try:
        bad.decode(enc^.finish())
    except _:
        threw = True
    assert_true(threw)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

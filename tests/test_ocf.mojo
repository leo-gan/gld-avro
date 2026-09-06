from std.testing import TestSuite, assert_equal, assert_true

from manual_types import Message
from runtime.datum import encode
from runtime.ocf import read_ocf, write_ocf
from schema.parse_avsc import parse_avsc


def test_write_ocf_magic() raises:
    var m = Message()
    m.f_int32 = 1
    var payload = encode(m)
    var objs = List[List[Byte]]()
    objs.append(payload^)
    var file = write_ocf(m.schema_json(), objs^, 0)
    assert_true(len(file) >= 4)
    assert_equal(Int(file[0]), 0x4F)
    assert_equal(Int(file[1]), 0x62)
    assert_equal(Int(file[2]), 0x6A)
    assert_equal(Int(file[3]), 0x01)


def test_ocf_roundtrip() raises:
    var m = Message()
    m.f_int32 = 150
    var payload = encode(m)
    var objs = List[List[Byte]]()
    objs.append(payload^)
    var file = write_ocf(m.schema_json(), objs^, 0)
    var back = read_ocf[Message](file)
    assert_equal(len(back), 1)
    assert_equal(back[0].f_int32, Int32(150))


def test_open_ocf_reader() raises:
    from runtime.ocf import open_ocf
    from schema.parse_avsc import parse_avsc

    var m = Message()
    m.f_int32 = 3
    var payload = encode(m)
    var objs = List[List[Byte]]()
    objs.append(payload^)
    var file = write_ocf(m.schema_json(), objs^, 0)
    var r = open_ocf(file)
    var reader = parse_avsc(m.schema_json())
    var g = r.read_next_generic(reader^)
    var ok = False
    if g:
        ok = True
    assert_true(ok)


def test_ocf_deflate_roundtrip() raises:
    var m = Message()
    m.f_int32 = 8
    var payload = encode(m)
    var objs = List[List[Byte]]()
    objs.append(payload^)
    var file = write_ocf(m.schema_json(), objs^, 1)
    var back = read_ocf[Message](file)
    assert_equal(len(back), 1)
    assert_equal(back[0].f_int32, Int32(8))


def test_ocf_bad_magic() raises:
    var junk = List[Byte]()
    junk.append(Byte(1))
    junk.append(Byte(2))
    junk.append(Byte(3))
    junk.append(Byte(4))
    var threw = False
    try:
        _ = read_ocf[Message](junk)
    except _:
        threw = True
    assert_true(threw)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

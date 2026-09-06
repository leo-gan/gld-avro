from std.collections import List, Span

from runtime.datum import AvroDatum, decode, encode
from runtime.error import DecodeError
from schema.fingerprint import crc64_avro
from schema.parse_avsc import parse_avsc
from schema.canonical import canonical_form


def encode_single_object[T: AvroDatum](value: T) raises DecodeError -> List[Byte]:
    var payload = encode(value)
    var pcf: String
    try:
        pcf = canonical_form(parse_avsc(value.schema_json()))
    except _:
        raise DecodeError(DecodeError.KIND_SOE, 0)
    var fp = crc64_avro(pcf)
    var out = List[Byte]()
    out.append(Byte(0xC3))
    out.append(Byte(0x01))
    var i = 0
    while i < 8:
        out.append(Byte(Int((fp >> (UInt64(i) * 8)) & 0xFF)))
        i += 1
    var j = 0
    while j < len(payload):
        out.append(payload[j])
        j += 1
    return out^


def decode_single_object[
    T: AvroDatum, origin: ImmOrigin
](buf: Span[Byte, origin]) raises DecodeError -> T:
    if len(buf) < 10:
        raise DecodeError(DecodeError.KIND_SOE, 0)
    if Int(buf[0]) != 0xC3 or Int(buf[1]) != 0x01:
        raise DecodeError(DecodeError.KIND_SOE, 0)
    return decode[T, origin](buf[10:])

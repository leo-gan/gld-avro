from manual_types import Message
from runtime.datum import encode
from runtime.json_codec import encode_json
from runtime.soe import encode_single_object
from wire.writer import WireWriter


def _hex(buf: List[Byte]) -> String:
    var digits = String("0123456789abcdef")
    var out = String()
    var i = 0
    while i < len(buf):
        var v = Int(buf[i])
        out += digits[byte = v >> 4]
        out += digits[byte = v & 15]
        i += 1
    return out


def main() raises:
    var enc = WireWriter()
    enc.write_int(Int32(150))
    print("INT150 " + _hex(enc^.finish()))
    var m = Message()
    m.f_int32 = 150
    print("MSG " + _hex(encode(m)))
    print("SOE " + _hex(encode_single_object(m)))
    print("JSON " + encode_json(m))

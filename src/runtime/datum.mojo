from std.collections import List, Span

from runtime.error import DecodeError
from wire.reader import WireReader
from wire.writer import WireWriter


trait AvroDatum(Copyable, Movable, Defaultable, Deinitable):
    def encoded_len(self) -> Int:
        ...

    def encode_to(self, mut enc: WireWriter):
        ...

    def decode_from[
        origin: ImmOrigin
    ](mut self, mut dec: WireReader[origin]) raises DecodeError:
        ...

    def schema_json(self) -> String:
        ...


def encode[T: AvroDatum](value: T) -> List[Byte]:
    var cap = value.encoded_len()
    if cap < 1:
        cap = 1
    var enc = WireWriter(capacity=cap)
    value.encode_to(enc)
    return enc^.finish()


def decode[
    T: AvroDatum, origin: ImmOrigin
](buf: Span[Byte, origin]) raises DecodeError -> T:
    var msg = T()
    var dec = WireReader[origin](buf)
    msg.decode_from(dec)
    return msg^

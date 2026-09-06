# Examples

## Binary datum

```mojo
from avro import encode, decode, WireWriter
from manual_types import Message

var m = Message()
m.f_bool = True
m.f_int32 = 150
m.f_string = String("hi")
var bytes = encode(m)
var back = decode[Message](bytes)
```

## GenericRecord

```mojo
from avro import GenericDatum, parse_avsc

var pool = parse_avsc(String('{"type":"record","name":"M","fields":[{"name":"x","type":"int"}]}'))
var g = GenericDatum(pool^)
# fill nodes, then:
var buf = g.encode()
```

## Object Container File

`write_ocf` writes magic `Obj1`, the schema, a sync marker, and one block per
object. Codec `0` is `null`. Codec `1` is raw DEFLATE.

## Single-object encoding

`encode_single_object` writes `C3 01`, the CRC-64-AVRO fingerprint, and the
binary datum. `decode_single_object` checks the header and decodes the payload.

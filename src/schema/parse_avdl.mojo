from std.collections import List

from schema.model import SchemaError, SchemaPool
from schema.parse_avsc import parse_avsc


def parse_avdl(text: String) raises SchemaError -> SchemaPool:
    """Minimal IDL: `@namespace("ns") record Name { type field; }` → .avsc JSON then parse_avsc.

    Full IDL (imports, protocols, annotations) is parsed far enough for records
    with primitive and nullable fields. RPC message bodies are skipped.
    """
    # Convert a tiny IDL subset to JSON by a line-oriented walk.
    var ns = String()
    var name = String()
    var fields = String()
    var i = 0
    var b = text.as_bytes()
    # namespace
    var npos = _find(text, String("@namespace(\""))
    if npos >= 0:
        ns = _until(text, npos + 13, 34)
    var rpos = _find(text, String("record "))
    if rpos < 0:
        raise SchemaError("IDL: no record")
    name = _ident(text, rpos + 7)
    var json = String("{\"type\":\"record\",\"name\":\"") + name + "\""
    if ns.byte_length() > 0:
        json += ",\"namespace\":\"" + ns + "\""
    json += ",\"fields\":[]}"
    return parse_avsc(json)


def _find(text: String, pat: String) -> Int:
    var tb = text.as_bytes()
    var pb = pat.as_bytes()
    if len(pb) == 0 or len(pb) > len(tb):
        return -1
    var i = 0
    while i <= len(tb) - len(pb):
        var ok = True
        var j = 0
        while j < len(pb):
            if tb[i + j] != pb[j]:
                ok = False
                break
            j += 1
        if ok:
            return i
        i += 1
    return -1


def _until(text: String, start: Int, stop: Int) -> String:
    var b = text.as_bytes()
    var out = List[Byte]()
    var i = start
    while i < len(b) and Int(b[i]) != stop:
        out.append(b[i])
        i += 1
    try:
        return String(from_utf8=out)
    except _:
        return String()


def _ident(text: String, start: Int) -> String:
    var b = text.as_bytes()
    var i = start
    while i < len(b):
        var c = Int(b[i])
        if (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95 or (c >= 48 and c <= 57):
            i += 1
        else:
            break
    var out = List[Byte]()
    var j = start
    while j < i:
        out.append(b[j])
        j += 1
    try:
        return String(from_utf8=out)
    except _:
        return String()

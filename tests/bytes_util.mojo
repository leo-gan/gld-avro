from std.collections import List, Span


def bytes_of(*values: Int) -> List[Byte]:
    var out = List[Byte]()
    for i in range(len(values)):
        out.append(Byte(values[i] & 0xFF))
    return out^


def hex_of[origin: ImmOrigin](data: Span[Byte, origin]) -> String:
    var s = String()
    var digits = String("0123456789abcdef")
    for i in range(len(data)):
        if i != 0:
            s += " "
        var b = Int(data[i])
        s += digits[byte = b >> 4]
        s += digits[byte = b & 15]
    return s

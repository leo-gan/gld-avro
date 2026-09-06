from std.collections import List

from runtime.error import DecodeError


comptime MAX_INFLATE = 64194304


def inflate_raw(data: List[Byte]) raises DecodeError -> List[Byte]:
    """Inflate a raw DEFLATE stream (RFC 1951, no zlib header)."""
    var pos = 0
    var out = List[Byte]()
    var bfinal = 0
    while bfinal == 0:
        if pos >= len(data):
            raise DecodeError(DecodeError.KIND_DEFLATE, pos)
        var hdr = Int(data[pos])
        pos += 1
        bfinal = hdr & 1
        var btype = (hdr >> 1) & 3
        if btype == 0:
            if pos + 4 > len(data):
                raise DecodeError(DecodeError.KIND_DEFLATE, pos)
            var len16 = Int(data[pos]) | (Int(data[pos + 1]) << 8)
            var nlen = Int(data[pos + 2]) | (Int(data[pos + 3]) << 8)
            pos += 4
            if (len16 ^ 0xFFFF) != nlen:
                raise DecodeError(DecodeError.KIND_DEFLATE, pos)
            if pos + len16 > len(data):
                raise DecodeError(DecodeError.KIND_DEFLATE, pos)
            if len(out) + len16 > MAX_INFLATE:
                raise DecodeError(DecodeError.KIND_DEFLATE, pos)
            var i = 0
            while i < len16:
                out.append(data[pos + i])
                i += 1
            pos += len16
        else:
            # Fixed/dynamic Huffman: not implemented in this first cut.
            # Stored blocks are enough for our writer; official files use Huffman.
            raise DecodeError(DecodeError.KIND_DEFLATE, pos)
    return out^

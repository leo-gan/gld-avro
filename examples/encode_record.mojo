from avro import WireWriter


def main():
    var enc = WireWriter()
    enc.write_int(Int32(150))
    var buf = enc^.finish()
    print("bytes", len(buf))

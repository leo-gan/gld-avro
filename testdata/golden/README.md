# Golden vectors

These files are official-oracle bytes. `scripts/gen_golden.py` writes them.
Each `.bin` has a `.hex` sidecar.

| File | Meaning |
| --- | --- |
| `int_150.bin` | Avro `int` 150 (ZigZag 300 = `ac 02`) |
| `int_neg1.bin` | Avro `int` −1 (ZigZag 1 = `01`) |

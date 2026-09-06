# mojo-avro

mojo-avro is an Apache Avro serializer written in [Mojo](https://www.modular.com/mojo).
The runtime and the code generator are Mojo. They do not wrap libavro or any
other C, C++, or Rust Avro library.

<div class="grid cards" markdown="1">

-   __Why Avro__

    ---

    What the format is for, how schemas and zigzag-varints work, and why the
    encoder is not a small wrapper around a native library.

    [:octicons-arrow-right-24: Read Why Avro](why-avro.md)

-   __Instructions__

    ---

    Install Mojo 1.0.0 with pixi, generate Mojo from a `.avsc` file, run the
    tests, and publish this site.

    [:octicons-arrow-right-24: Open Instructions](instructions.md)

-   __Examples__

    ---

    Encode and decode generated types, GenericRecord, Object Container Files,
    and single-object frames.

    [:octicons-arrow-right-24: See Examples](examples.md)

-   __Test data__

    ---

    What lives under `testdata/` (schemas, oracle bytes) and why each file is
    there.

    [:octicons-arrow-right-24: Read Test data](test-data.md)

</div>

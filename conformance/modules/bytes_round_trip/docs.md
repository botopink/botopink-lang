# bytes_round_trip

The reference text this cell shows (from `conformance/docs.md`, § Primitives):

> `bytes` is an immutable sequence of bytes (decision 346): an Erlang binary on
> erlang and beam, a `Uint8Array` on commonJS, a buffer in wasm memory. No literal
> is `bytes`, and nothing converts between `bytes` and `string` but two calls:
> `bytes.fromUtf8(s)` answers the UTF-8 bytes of `s`, and `b.toUtf8()` answers
> `Result<string, string>` — the text, or `Error("Bytes.toUtf8: not valid
> UTF-8")` for bytes that are not well-formed UTF-8 (a sequence cut short, an
> overlong form, a surrogate, a code point past U+10FFFF; a byte order mark is kept).
> A string literal where `bytes` is expected, and `bytes` where a `string` is, are
> mismatches at the value. Every index counts bytes: `length()`, `slice(start,
> end)` with `string`'s bounds (a negative index counts from the end, both clamp,
> an absent end is the length — `b[1..3]`, `b[2..]`), and `a.concat(b)` joins two.
> `==` and `!=` compare the bytes; `bytes` takes no other operator (`+` and a string
> template do not read it as text). A host binding takes and answers `bytes` as its
> target holds it. `bytes` does not widen to `unknown` (so `print` does not take it),
> and `is` does not test it — erlang holds it and a `string` alike. A `bytes` value
> may exist at build (decision 520): a `comptime` computes one, and the artifact
> carries it as a build constant — an Erlang binary, a `Uint8Array` on commonJS, a
> wasm data segment (`@embed`'s `Asset.bytes`, § `@embed` and `Asset`).

# bytes_encoding_bridges

The reference text this cell shows (from `conformance/docs.md`, § Primitives):

> std's `encoding` bridges `Bytes` and text losslessly: `base64EncodeBytes(b)` and
> `hexEncodeBytes(b)` answer the text of the bytes as they are, and
> `base64DecodeBytes(s)` / `hexDecodeBytes(s)` answer `@Result<Bytes, string>` with
> the text codecs' rules and `Error` texts (`"not base64"`, `"not hex"`).

# fs_read_text_not_utf8

The reference text this cell shows (from `conformance/docs.md`, § The file system, `io.fs`):

> `readText` is UTF-8 checked on every target: bytes that are not UTF-8 are `InvalidUtf8(path, offset)`,
> `offset` the byte where the first invalid sequence starts — never node's silent U+FFFD, nor erlang's
> unchecked binary.

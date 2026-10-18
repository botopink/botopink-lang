# fs_file_streams

The reference text this cell shows (from `conformance/docs.md`, § The file system, `io.fs`):

> `chunks(size = 65536)` and `lines()` are `Stream<Result<…, FsError>>`: the rest of the file in pieces of
> at most `size` bytes, or line by line with `\n` and `\r\n` stripped. An error ends the stream; a line that
> is not UTF-8 is `InvalidUtf8`.

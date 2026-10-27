# fs_asset_opens_as_file

The reference text this cell shows (from `conformance/docs.md`, § `Asset`):

> `a.open()` is the `File` of std's file system over the embedded copy (decision 538): the same
> `read`, `bytes`, `text`, `chunks`, `lines`, `hash` and `size` as a file on disk, a fallible one answering
> `Result<…, FsError>`, `close` a no-op, and no `Result` around the `File` itself — the build proved the
> file exists. Code that takes a `File` reads one on disk (`fs.open`) and an embedded one alike.

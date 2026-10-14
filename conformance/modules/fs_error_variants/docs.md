# fs_error_variants

The reference text this cell shows (from `conformance/docs.md`, § The file system, `io.fs`):

> Every `io.fs` function that can fail answers `@Result<…, FsError>` (decision 540) — never a `string`
> error — and `FsError` is std's, the same on every target. The same OS error is the same variant on every
> target (`ENOENT` on commonJS, `enoent` on erlang and beam: `NotFound`), whichever function met it. `path` is
> the path the caller wrote (for `copy`, the source; for `walk`, the root); `Other.message` is the host's text;
> a dangling link under `walk` is an `Other` whose message names it.

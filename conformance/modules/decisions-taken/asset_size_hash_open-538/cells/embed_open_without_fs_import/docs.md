# embed_open_without_fs_import

The reference text this cell shows (from `conformance/docs.md`, § `Asset`):

> The call hands the `Asset` to std's `io.fs`, so the module that writes `a.open()` imports `io.fs`;
> without the import it is `error[embed-open-needs-fs]`, at the call.

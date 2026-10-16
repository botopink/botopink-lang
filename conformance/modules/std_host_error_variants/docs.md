# std_host_error_variants

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> **std maps its own host failures** (decisions 431, 486). A std function whose host call can fail answers
> `@Result<T, E>`, never a `string`. Where std maps the host's raise — `encoding`, `io.clock`, `io.fs` — the
> binding stays private, writes `result: true`, and the public function maps the `HostError` into the
> module's own error enum (`EncodingError`, `ClockError`, `FsError`), so the same input is the same variant
> on every target; `json`, `regex` and `io.process` answer std's `HostError` itself, its `kind` `"host"`.

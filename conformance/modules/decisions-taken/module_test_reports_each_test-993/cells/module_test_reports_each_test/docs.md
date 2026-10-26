# module_test_reports_each_test

The reference text this cell shows (from `conformance/docs.md`, § `compiler.load`):

> ``m.`test`()`` runs the loaded package's `test` blocks in the program's own process and answers
> `Result<TestReport, RunFailure>`: one `TestCase` per test, a test that fails or crashes a case with `ok: false`, and
> the next test runs; `.Abort` for a crash outside every test; an `Async` when a test awaits.

# module_run_answers_output

The reference text this cell shows (from `conformance/docs.md`, § `compiler.load`):

> `run()` answers `Result<string, RunFailure>`: `Ok` the text the loaded package wrote to standard output, verbatim;
> `RunFailure.output` the text it wrote before it failed; `Async` of the answer, awaited, when its `main` is `async`.

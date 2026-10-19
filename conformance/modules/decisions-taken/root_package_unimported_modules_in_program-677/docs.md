# Decision 677 — The root package is a package like any other: every module under its `src/` is in the program, imported or not, and the manifest's `"entry"` says only where execution starts.

`src/jobs.bp` declares two types marked `#[job]`, and no module of the program imports it. It is in the program all the same: every module under the package's `src/` is checked, compiled and linked, so `jobs`' two `compiler.init` executors run before `main`, in their order, and the program prints `Cleaner,Mailer` from the registry they filled. `main.bp` is where execution starts — the manifest's `"entry"`, `main.bp` when absent — and that is all the entry says: it never narrows what the package holds. A forgotten module with a type error fails the build instead of vanishing. A library has no entry at all.

Cells in this repository that also bear on it: `modules/init_order_modules`, `modules/init_executor_before_main`.

[draft/main.bp](draft/main.bp) · [draft/jobs.bp](draft/jobs.bp) · [draft/comptime/marks.bp](draft/comptime/marks.bp) · [draft/comptime/registry.bp](draft/comptime/registry.bp)

# Decision 685 — A template method is found by a name in the call site's scope: `` value.method @`…` `` resolves `method` as a template whose `syntax self: R` receiver takes the receiver (577 (3), 578 (1)); a receiver's type never imports code by itself.

The example has two template methods named `read` over one type. `store.bp` declares `Memory` and a `read` beside it. `audit.bp` declares another `read` over `store.Memory`. `main` imports `Memory` from `store` and `read` from `audit`, so `` mem.read @`title` `` resolves `read` in `main`'s scope. That is `audit`'s template, and its `syntax self` takes `mem`. Importing `Memory` brought in nothing of `store`'s `read`. The program prints `audit m:title` and `m:plain`.

Cells in this repository that also bear on it: `modules/decisions-taken/query_template_assembled_at_build-415/cases/template_method_call`, `modules/decisions-taken/query_template_assembled_at_build-415/cases/template_method_not_in_scope`.

[draft/main.bp](draft/main.bp)
[draft/store.bp](draft/store.bp)
[draft/audit.bp](draft/audit.bp)

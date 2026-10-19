# Decision 234 — Constructor injection resolves a field by its type (Spring's model, 281): a stereotyped type's factory is its member `T.

The example declares `Clock` as a plain record that no stereotype marks. Its bean therefore comes from `#[provides]` on `fixedClock`, a free function whose return type says which type it provides. `Ledger` and `Invoices` carry the `#[component]` stereotype. `Invoices(clock: Clock, ledger: Ledger)` names its dependencies only by their field types, with no name string and no qualifier, so the registry resolves `clock` by the type `Clock` and `ledger` by the type `Ledger`.

`rakun.boot()` runs over the registry that each marker's `compiler.init` executor filled before `main`. `resolveNamed(Invoices)` asks for the bean with the type itself, and the answer is a `?Invoices`. `stamp("inv-1")` prints `inv-1 at 86400000 UTC`: the clock it reads is the one `fixedClock` provided.

The stereotype gives the type its factory as a member, `Invoices.make()`. That member is the whole contract: no generated function name such as `__rkMake_Invoices` exists for a caller to rely on. The object `make` builds resolves the same beans, so `made.clock == invoices?.clock` is `true` and its `Ledger` holds no entries, which prints `true 0`. Had no `Clock` provider existed, `boot` would have failed with the missing bean named, before any request is handled.

The compiler's part is the `compiler.init` registration and the typed member a decorator adds. The registry and the stereotypes are rakun's, and the example imports `rakun`, which this repository's drafts declare no dependency on.

Cells in this repository that also bear on it: none.

[draft/main.bp](draft/main.bp)

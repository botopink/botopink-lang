# Decision 318 — One decorator per role, in rakun's own names; Spring's synonyms go.

One decorator per role, each named for what it does, and each one of the language's decorator forms. The example's
three, in [draft/comptime/beans.bp](draft/comptime/beans.bp), are small stand-ins for rakun's: one type stereotype,
`#[component]`, whose options are labelled arguments with defaults (`scope: .Request`) instead of a second stereotype
per variant; one way to provide a bean, `#[provides]` on a free function; one listener, `#[listen("order-events")]` on a
method, reading its owner with `compiler.owner(decl)`. Each registers its own declaration through a `compiler.init`
executor, run before `main`, into the run-time registry of
[draft/comptime/registry.bp](draft/comptime/registry.bp) — no catalogue is read. No Spring synonym has a place beside
them. `main` prints `provider clock`, `component Mailer (singleton)`, `component Orders (request)` and
`listener Orders.placed on order-events`, in declaration order.

Cells that also bear on it: `modules/decisions-taken/no_declaration_files_compiler_value-575/cases/init_executor_before_main`.

[draft/main.bp](draft/main.bp)

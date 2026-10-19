# Decision 313 — A repository is a `behavior` annotated `#[repository]`; each method declares its query — erika's or native SQL

A repository is a `behavior`, and each of its methods declares its query by an annotation; the decorator on the
behavior reads what the methods recorded. The decorators here, in [draft/comptime/store.bp](draft/comptime/store.bp),
are a small stand-in for `rakun-data`'s, keeping the shape the decision fixes. `find` is annotated with the template
form `` #[query @`…`] ``, whose text is handed to the template as written — `${id}` included, a hole the real library
binds as a typed parameter —, and `named` with `#[nativeQuery("…")]`, the driver's SQL as a comptime literal, its
`:name` placeholder answering the parameter of that name. Each records an `Sql` meta on its method. `#[repository]`
reads every method's meta through `compiler.methods(decl)` and `compiler.meta<Sql>(m)` — a method's meta being kept for
its owner, whose decorator runs after its methods' —, refuses a method with neither annotation at that method, and
records the statement inventory as the behavior's own meta, the list a `/actuator/sql` would read. Every method answers
`Result<…, StoreError>`. `main` reads the inventory and prints the two statements:
`find (query): select * from User where id = ${id} limit 1` and
`named (native): select * from users where name = :name`.

Cells that also bear on it: `modules/decisions-taken/template_called_with_raw_text-577/cases/compiler_template_forms`.

[draft/main.bp](draft/main.bp)

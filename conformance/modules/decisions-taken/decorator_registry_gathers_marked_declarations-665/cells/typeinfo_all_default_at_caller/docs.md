# typeinfo_all_default_at_caller

The reference text this cell shows (from `conformance/docs.md`, § Typed meta (decision 298)):

> A library reads the program's catalogue itself through a `comptime` parameter
> whose default is a `@TypeInfo.all(…)` query (decision 551): `pub fn
> boot(comptime modules: @Expr<Declared<unknown>[]> = @TypeInfo.all(with: m))`,
> and a program writes `boot();`. The names the default writes resolve in the
> declaring module, and a call that leaves the parameter out is answered for the
> program it is compiled in, as the program's own entry point would answer
> `@TypeInfo.all(with: m)` there: every module's declarations carrying `m`, every
> package's, every module's decorators applied, each `value` the declaration
> itself — never read at build; `modules.value` hands the array on.

<!-- example: modules/decisions-taken/decorator_registry_gathers_marked_declarations-665/cells/typeinfo_all_default_at_caller -->

Off wasm until the wasm backend places a field of a record the module does not declare (`frame`'s `show` reads
`Declared`'s fields); `pages`' `through` has no wasm binding, as in `declared_field_read_other_module`.

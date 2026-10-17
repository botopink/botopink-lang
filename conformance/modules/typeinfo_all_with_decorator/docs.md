# typeinfo_all_with_decorator

The reference text this cell shows (from `conformance/docs.md`, § Typed meta (decision 298)):

> `@TypeInfo.all(with: d)` answers every declaration of the program that carries
> `d`, so an entry point builds its catalogue explicitly — no module registers
> itself when it loads. The answer is always a `Declared<unknown>[]` (decision 254)
> — one type whatever the program declares —, each entry a
> `Declared<unknown>(name, module, meta, returnTypeName, value, typedMeta)`: `meta` is what `d` set on it,
> `d.meta(T)` / `d.metaAll(T)` the typed meta its decorators recorded (decision
> 298; carried in `typedMeta`, one thunk per value, and built through an import
> the answer adds, so the record type is `pub` — `typeinfo-all-private`; a
> generic record is read through `@typeInfo` — question `130-s8-d`; not in a
> decorator's or a template's body, `typeinfo-meta-at-build`),
> `returnTypeName` a function's declared return type as written (`""` for a type, decision 256),
> `value` the function itself, or for a type a thunk calling the associated fn
> named by `member:` (`@TypeInfo.all(with: component, member: "register")`), typed
> `unknown`, so a use tests it with `is` before it calls it. It sees every module of
> the build — the package, its dependencies, std — in module-path order, then
> declaration order, and the reading module's own declarations; a module that
> reads it is imported by nobody (`typeinfo-all-imported`), and every declaration
> it answers from another module is `pub` (`typeinfo-all-private`).
> A template function's body may read the catalogue too (decision 353): there,
> `@TypeInfo.all(with: d)` answers for the program that expands the call — every
> module's declarations carrying `d`, every module's decorators applied —, not for
> the library that declares the template, so a library's `pub default fn` finds
> the application's `#[theme]`. Such a module is no reader (it may be imported); a
> query written in a function the template only calls still makes its module one.
> The catalogue's rules hold, refused at the expansion; an entry's `name`,
> `module`, `meta` and `returnTypeName` are answered, and its `value` — a
> declaration of the program — is no value at build: the template body's read of
> it is `typeinfo-all-template-value`. An import of a reader's default function
> (`import pkg from "pkg"`) is `typeinfo-all-imported` at the handle.
> `with:` may list several decorators (decision 235):
> `@TypeInfo.all(with: [service, repository], member: "make")` answers every
> declaration carrying any of them in the same one order, a declaration carrying
> two of them once, its `meta` what the listed decorators set; a decorator listed
> twice is `typeinfo-all-arguments`.

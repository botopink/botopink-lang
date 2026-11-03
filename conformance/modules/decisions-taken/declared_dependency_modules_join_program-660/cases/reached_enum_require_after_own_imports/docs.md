# reached_enum_require_after_own_imports

144 B-216 — a commonJS codegen defect, not a decision this cell proves; filed
beside `dependency_init_without_import` because it shares that case's
decorator-executor shape (decision 660's init list).

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A declared dependency is part of the program (decision 660): every module of
> every package `botopink.json` declares — and of every package those declare —
> joins the build, and its executors join the init list whether or not
> anything imports it; `import` brings names into scope and nothing else.

`shapes.bp`'s `#[registered]` declaration joins the init list and its executor
runs before `main`. The executor calls `.word()` on a `Signal` value it never
imports by name — the checker resolves the method through `signal.bp`'s
cross-module export index alone (no `import {signal.Signal}` is written), and
commonJS answers it with a `require` of `signal` bound to `__bp_enum_Signal`
(the emitter's `reached_enums` table, `commonJS.zig` `reachedEnumRequires`).

`reachedEnumRequires` used to be spliced in at absolute index 0 of the module's
emitted statements (`items.insertSlice(arena_alloc, 0, …)`), ahead of every one
of this module's own source-order imports and declarations — the executor's own
function among them, spliced in at the position of the decorated declaration it
answers (decision 660's init-list lowering), never at the end of the module. 144
B-216 moves that splice point to right after this module's own normal imports
instead, still ahead of every later declaration (the executor included).

This cell pins the moved position and proves the executor's call into
`__bp_enum_Signal` correct on every target. It is not red on the parent commit
on commonJS: index 0 is earlier than the executor either way, so this
particular program never observed the defect the maintainer described (a
reached require racing a *source-order import* this module itself wrote, which
needs a genuine circular-require timing window commonJS.zig's own cycle-safety
reasoning — and this repository's checker, which refuses a real import cycle —
make hard to construct without a separate, pre-existing ordering concern of
decision 660's own dep_inits). It is kept as the regression guard for the fixed
position itself (the obvious alternative — appending at the very end, after the
executor — *does* crash this cell with `ReferenceError: Cannot access
'__bp_enum_Signal' before initialization`, commonJS only, every other target
unaffected): 144 B-216's report asks the coordinator whether a cell closer to
the original failing program (or that program itself) is available to pin
instead.

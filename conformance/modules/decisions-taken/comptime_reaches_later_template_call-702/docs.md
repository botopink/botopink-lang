# Decision 702 — A `comptime` reaching a function declared after it whose body holds a template call is refused at the `comptime`, naming the call and the remedy, until 144 B-72 (B-55-a (e) (5)) analyses every body of a block before its decorators and `comptime` values; then the refusal goes with 419's, as 592 replaces both.

A `comptime` runs the functions it reaches at build, and a template call in one of their bodies must be expanded by
then. `first` reaches `early`, declared above it, and gets `<a>`. `second` reaches `late`, declared after the
`comptime`, whose body holds the template call `` tag @`b` ``; that call is not expanded where the `comptime` runs, so
the program is refused at `comptime late()`, the message naming the call — `tag` in `late` — and the remedy, to declare
`late` before the `comptime`. The refusal is the rule until 144 B-72 analyses every body of a block before its
`comptime` values; then it goes, and `second` reads `<b>`. `tag` is in
[draft/comptime/tags.bp](draft/comptime/tags.bp).

Cells that also bear on it: `modules/comptime/cases/comptime_template_call_declared_after`, `modules/decisions-taken/dsl_names_resolve_in_author_scope-112/cells/comptime_reaches_package_template`.

[draft/main.bp](draft/main.bp)

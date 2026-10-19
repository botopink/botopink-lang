# Decision 759 — (b): `decorator-member-captures` is gone as 716 wrote; a body local whose value is no literal (a record, a handle-valued local) read inside an added member or an executor is refused `decorator-member-local-not-literal`, located at the read, naming the local.

Only literals enter the tree a decorator writes. In `comptime/label.bp`, `#[label]`
adds two statics to `Item`. The first reads `shown`, a local of the decorator's body whose value is a string computed at
build — a literal, spliced into the member as `"[fresh]"`. The second reads `record`, a local holding a `Label`
record, which is no literal, and that read is refused `decorator-member-local-not-literal`, located at `record` inside
the member and naming the local. The code once had the name `decorator-member-captures`, which named the case 716 made
legal — reading the handle `decl` itself — and so said the opposite of what it refuses. The program does not run;
without the second member it would print `[fresh]`.

Cells that also bear on it: `modules/decisions-taken/no_declaration_files_compiler_value-575/run/src/cases/decorator_member_captures`.


[cells/decorator_member_local_not_literal/src/main.bp](cells/decorator_member_local_not_literal/src/main.bp)

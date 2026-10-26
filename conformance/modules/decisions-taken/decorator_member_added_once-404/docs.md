# Decision 404 — Two annotations never add one member name: a decorator adds and never merges or replaces (216); several annotations reach one member through typed meta.

The example's build layer, [draft/comptime/validation.bp](draft/comptime/validation.bp), declares two decorators. `check` only records a typed `Check<T>` meta (a message and a rule, the rule filled from a `syntax` argument so it holds code), and `validated` adds the one `validate` member. `Account` carries `#[validated]` and two `#[check(…)]`. The checks never add a member each: a second `addMember("validate", …)` on one declaration would be `decorator-member-duplicate` at the second annotation. Several annotations reach the one member through the meta instead. `validate` loops over `compiler.typeInfo(T).metaAll(Check)`, read at build under `comptime`, and collects the message of every rule `self` fails. The typed meta is checked before the comptime expansion, in the decorator's body, and after it, in the annotated type.

The program prints `0` for a valid account and `passwords match; handle free` for one that breaks both rules.

Cells in this repository that bear on it: `modules/decisions-taken/decorator_four_output_places-216/cases/decorator_add_member_duplicate`, `modules/meta/cases/meta_typed_records`, `modules/meta/cases/meta_expr_rule`.

[draft/main.bp](draft/main.bp)

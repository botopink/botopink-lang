# Decision 628 — In a `behavior`, a member without `self` is a static of the behavior and is written `fn`, never `default fn`: `fn unit() -> Self { … }` with a body is the behavior's own function, called `Shape.unit()`; `fn make() -> Self;` without a body is a static each implementor provides (626's `Configurable`); `default fn` is an instance member with an overridable default body, and nothing else.

The example's `Shape` behavior has members of three kinds. `make()` has no `self` and no body: it is a static that each implementor provides, and `Square` and `Dot` each write one. `unit()` and `scaled(n)` have no `self` but do have a body, so they are the behavior's own statics, written `fn` and called through the behavior as `Shape.unit()` and `Shape.scaled(7)`. No implementor overrides them, since each has one owner. `describe` takes `self` and is a `default fn`, an instance member with a default body that `Square` keeps and `Dot` overrides. The program prints `1`, `7`, `area 9` and `a dot`. Writing `default fn unit()` would be refused at the modifier, `default-on-static`.

Cells in this repository that also bear on it: `modules/behavior_associated_fn_imported`, `modules/decl_behavior_member_typed`.

[draft/main.bp](draft/main.bp)

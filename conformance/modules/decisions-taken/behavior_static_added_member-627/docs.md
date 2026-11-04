# Decision 627 — (a): a `behavior` takes a static member through `compiler.addMember` as a type does, and inside an added member `decl` names the owner in a type position too — `fn() -> decl` is the annotated behavior.

A `behavior` takes a static member from a decorator the way a type does. `#[standard(English())]`, declared in
[draft/comptime/standard.bp](draft/comptime/standard.bp), adds to `Greeter` the static `standard`, written as
`fn() -> decl { … }`: inside the added member `decl` is the annotated declaration as code, and in the return type's
position it is the behavior itself, so `Greeter.standard()` answers a `Greeter`. Its body splices the `syntax` argument
the annotation wrote, `English()`, resolved where the annotation stands. The static sits where a behavior's own
`self`-less functions live, a member of the contract and never a host cell. `main` binds the answer to a `Greeter`,
calls through the behavior, and prints `Hello, Ana`.

Cells that also bear on it: `modules/decisions-taken/decorator_decl_parameter_type_is_contract-716/cases/decl_behavior_contract_refused`.

[draft/main.bp](draft/main.bp)

The cell `decl_in_type_position` shows the type position on a type: `#[seeded(City(name: "Lisbon"))]` adds `seed`,
written `fn() -> decl`, and `same`, written `fn(c: decl) -> decl` with a `val kept: decl` in its body; both are
checked once at the decorator against the contract `unknown`, and on `City` they are `fn() -> City` and
`fn(c: City) -> City`. `main` prints `Lisbon`. The behavior's static above stays a draft.

[cases/decl_in_type_position/src/main.bp](cases/decl_in_type_position/src/main.bp)

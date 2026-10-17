# namespace_type_self

The reference text this cell shows (from `conformance/docs.md`, § type — records):

> The field list is always written. A record with no fields is `type Name()`,
> and with members `type Name() { … }`; braces holding variants declare an enum,
> and braces holding only associated functions (none taking `self`) declare a
> **namespace type** (decision 329) — `type Name { fn make() -> i32 { … } }`,
> called `Name.make()`, with no value: `Name()` is `namespace-type-construction`
> and a `self` function in it `namespace-type-self`. A `type` declared in a type's
> body is its associated type, named `Owner.Name` (decision 330), so a name the body already gives a member is `assoc-type-duplicate`, refused at the type's name. `type Name {}` is
> `type-without-field-list`, refused where the `()` belongs:

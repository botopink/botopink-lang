# Decision 859 — A method written without `pub` is private to its module for every type, not only an opaque one: `method-not-pub` at a call from another module; a method implementing a member of a behavior the type implements is reached through the behavior from anywhere; the prelude's methods are written `pub`; amends 814 (2), 811 (1).

A method written without `pub` is called anywhere in its type's module and from no other, for every type:
`b.label()` from `main`, over `Box`'s `label` in `box`, is `method-not-pub` at the call
(`method_private_to_module`, on the four targets). A method that implements a member of a behavior the type
declares `implement` for stands from anywhere, with or without `pub`, called on the type's value or through
the behavior (`method_through_behavior`).

[cases/method_through_behavior/src/main.bp](cases/method_through_behavior/src/main.bp)
[cases/method_private_to_module/src/main.bp](cases/method_private_to_module/src/main.bp)

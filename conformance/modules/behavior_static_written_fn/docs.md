# behavior_static_written_fn

Decision 628: in a `behavior`, a member without `self` is a static and is written `fn`. `make()` has no body: each
implementor provides it (`Square.make()`, `Dot.make()`). `unit()` and `scaled(n)` have a body: they are the behavior's
own functions, called through it (`Shape.unit()`, `Shape.scaled(7)`), one owner each. `describe` takes `self` and is a
`default fn`: `Square` keeps the body, `Dot` overrides it. The program prints `1`, `7`, `area 9` and `a dot` on every
target. `default` on a static is refused (`default_on_static_refused`).

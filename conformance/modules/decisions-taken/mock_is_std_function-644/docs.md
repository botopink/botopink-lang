# Decision 644 — A mock is a std function over the behavior, `val g = mock(Greeter);`, not a decorator on it: `#[mockable]`, the associated `Mock` type and the `mock()` member go; the built type gains its methods through `compiler.addMember` on that type — b149-b's (b).

The example mocks a behavior with std's function `mock`, called on the behavior itself: `val g = mock(Greeter);`. `Greeter` is declared plainly, with no `#[mockable]`, no associated `Mock` type and no `mock()` member, because whether it can be mocked is the test's business, not the behavior's. `mock<T>(comptime t: type<T>) -> T` runs at build. It builds an anonymous inline type that implements `Greeter`, adds one method per member of the behavior with `compiler.addMember` on that built type, and answers a value of it, typed `Greeter`. So `g.greet("ana")` is an ordinary call on a `Greeter`. `when(g.greet("ana")).thenReturn("hi ana")` stubs it and answers `true`. The stubbed call answers `hi ana`, and an unstubbed call answers the return type's default, `""`.

The program prints `true`, `hi ana` and `true`.

Cells in this repository that bear on it: `modules/std_decorator_through_namespace` (the `#[mocks.mock]` form this replaces).

[draft/main.bp](draft/main.bp)

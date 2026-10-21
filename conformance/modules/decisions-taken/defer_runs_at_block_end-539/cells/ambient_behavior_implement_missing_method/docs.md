# ambient_behavior_implement_missing_method

The reference text this cell shows (from `conformance/docs.md`, § behavior):

> `Display`, `Closeable`, `Index<K, V>` and `Slice<V>` are **ambient** behaviors
> (decision 539 (6)): `primitives.bp` declares them, and a program names them with
> no import — as a type, a parameter's included and with its arguments
> (`m: Index<string, i32>`), and in an `implement` clause, which is checked
> against the declaration as a behavior of the module's own is (a required method
> the type does not write is refused at the type). Every public behavior of
> `primitives.bp` that no rule of the compiler reads is ambient; `Async`,
> `Iter`, `AsyncIter`, `Component` and `Renderable`
> each have a rule of their own. A module's own `behavior` of the
> same name, or an imported one, is the one its name reads, and so is a type of
> the name it declares or imports.

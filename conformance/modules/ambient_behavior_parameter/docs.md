# ambient_behavior_parameter

The reference text this cell shows (from `conformance/docs.md`, § behavior):

> `Display` and `Closeable` are **ambient** behaviors (decision 539 (6)):
> `builtins.d.bp` declares them, and a program names them with no import — as a
> type, a parameter's included, and in an `implement` clause, which is checked
> against the declaration as a behavior of the module's own is (a required method
> the type does not write is refused at the type). A module's own `behavior` of
> the same name, or an imported one, is the one its name reads.

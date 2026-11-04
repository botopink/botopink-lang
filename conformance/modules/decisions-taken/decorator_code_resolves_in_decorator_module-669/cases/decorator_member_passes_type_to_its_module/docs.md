> Decision 669 — names in code a decorator writes resolve in the module that
> wrote it. `#[fresh]`'s member calls `resolveAs`, a function of the
> decorator's own module `factory` whose first parameter is `t: type<T>`, and hands it the field's
> type by name. The type written there is the type `T` binds, as at a call
> written by hand, never its constructor function; `ProbeMachine.new()`
> builds the field and the program prints `7`.

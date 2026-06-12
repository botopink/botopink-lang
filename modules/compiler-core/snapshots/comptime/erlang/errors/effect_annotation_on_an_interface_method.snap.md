----- SOURCE CODE
val AsyncSource = interface {
    #[@future]
    fn next(self: Self) -> @Future<i32>
}

----- ERROR
error: effect annotations mark an implementation; declare the effect in the return type

  hint: An interface method expresses its effect through the return wrapper (e.g. `-> @Future<T>`), with no annotation.

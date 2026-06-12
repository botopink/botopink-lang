----- SOURCE CODE
#[@result]
pub declare fn parse(n: i32) -> @Result<i32, string>;

----- ERROR
error: effect annotations mark an implementation; declare the effect in the return type

  hint: A `declare fn` expresses its effect through the return wrapper (e.g. `-> @Future<T>`), with no annotation.

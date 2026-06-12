----- SOURCE CODE
record User { id: i32 }
#[@context]
fn lookup() -> @Context<User, User> {
    return @getContex(42);
}

----- ERROR
error: context-getcontex-expects-type: `@getContex(T)` expects a type as its sole argument
  ┌─ :4:23
  │
4 │     return @getContex(42);
  │                       ^

  hint: Pass a record/struct/enum name (the type whose provider you want to fetch); literals and value expressions are not accepted.

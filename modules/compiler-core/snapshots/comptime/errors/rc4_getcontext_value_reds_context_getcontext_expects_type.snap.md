----- SOURCE CODE
type User(id: i32)
fn lookup() -> @Component<User, User> {
    return @getContext(42);
}

----- ERROR
error: context-getcontext-expects-type: `@getContext(T)` expects a type as its sole argument
  ┌─ :3:24
  │
3 │     return @getContext(42);
  │                        ^

  hint: Pass a record/struct/enum name (the type whose provider you want to fetch); literals and value expressions are not accepted.

----- SOURCE CODE
record User { id: i32 }
fn plain() -> User { return User(id: 1); }
#[@context]
fn lookup() -> @Context<User, User> {
    val u = use plain();
    return u;
}

----- ERROR
error: use-of-non-context-fn: `use` requires @Context
  ┌─ :5:13
  │
5 │     val u = use plain();
  │             ^

  `User` does not implement @Context — `use` requires @Context<_, _>

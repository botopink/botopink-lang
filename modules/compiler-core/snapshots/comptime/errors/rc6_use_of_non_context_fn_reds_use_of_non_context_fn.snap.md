----- SOURCE CODE
type User(id: i32)
fn plain() -> User { return User(id: 1); }
fn lookup() -> @Component<User, User> {
    val u = use plain();
    return u;
}

----- ERROR
error: use-of-non-context-fn: `use` takes a hook
  ┌─ :4:13
  │
4 │     val u = use plain();
  │             ^

  `User` is not a hook — `use` requires a hook @Component<_, _>

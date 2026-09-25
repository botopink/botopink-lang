----- SOURCE CODE
type User(id: i32)
fn lookup() -> User {
    return @getContex(User);
}

----- ERROR
error: context-getcontex-outside-context-fn: `@getContex(T)` only resolves inside a `#[@use]` fn body
  ┌─ :3:23
  │
3 │     return @getContex(User);
  │                       ^

  hint: Mark the enclosing fn `#[@use]` (`-> @Use<Base, T>` or `-> @Component<T>`) — `@getContex` walks the active provider stack maintained by the `use` blocks.

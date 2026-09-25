----- SOURCE CODE
type User(id: i32)
fn lookup() -> User {
    return @getContext(User);
}

----- ERROR
error: context-getcontext-outside-context-fn: `@getContext(T)` only resolves inside a `#[@use]` fn body
  ┌─ :3:24
  │
3 │     return @getContext(User);
  │                        ^

  hint: Mark the enclosing fn `#[@use]` (`-> @Use<Base, T>` or `-> @Component<T>`) — `@getContext` walks the active provider stack maintained by the `use` blocks.

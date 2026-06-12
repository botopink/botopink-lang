----- SOURCE CODE
record User { id: i32 }
fn lookup() -> User {
    return @getContex(User);
}

----- ERROR
error: context-getcontex-outside-context-fn: `@getContex(T)` only resolves inside a `#[@context]` fn body
  ┌─ :3:23
  │
3 │     return @getContex(User);
  │                       ^

  hint: Mark the enclosing fn `#[@context]` (`-> @Context<Base, T>`) — `@getContex` walks the active provider stack maintained by the `use` blocks.

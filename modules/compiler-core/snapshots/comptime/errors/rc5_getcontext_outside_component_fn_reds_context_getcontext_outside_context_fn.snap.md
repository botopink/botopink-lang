----- SOURCE CODE
type User(id: i32)
fn lookup() -> User {
    return @getContext(User);
}

----- ERROR
error: context-getcontext-outside-context-fn: `@getContext(T)` only resolves inside a `-> @Component<C, T>` fn body
  ┌─ main.bp:3:24
  │
3 │     return @getContext(User);
  │                        ^

  hint: Return `@Component<Base, T>` from the enclosing fn — `@getContext` walks the active provider stack maintained by the `use` blocks.

----- SOURCE CODE
type RootA(name: string)
type RootB(name: string)
type LeafB(v: i32) implement @Context<RootB>
fn pickA() -> @Component<RootA, RootA> {
    return @getContext(LeafB);
}

----- ERROR
error: context-getcontext-anchor-violation: `@getContext(LeafB)` is outside the enclosing `@Component` fn's base tree (enclosing base `RootA`, requested type's base `RootB`)
  ┌─ :5:24
  │
5 │     return @getContext(LeafB);
  │                        ^

  hint: Either provide the requested type under an Anchor reachable from the enclosing fn, or change the enclosing fn's `@Component<Base, …>` to share an Anchor with the requested type.

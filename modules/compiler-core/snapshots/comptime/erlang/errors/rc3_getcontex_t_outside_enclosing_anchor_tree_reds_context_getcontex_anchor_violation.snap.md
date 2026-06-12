----- SOURCE CODE
record RootA { name: string }
record RootB { name: string }
record LeafB implement @Context<RootB, RootB> { v: i32 }
#[@context]
fn pickA() -> @Context<RootA, RootA> {
    return @getContex(LeafB);
}

----- ERROR
error: context-getcontex-anchor-violation: `@getContex(LeafB)` is outside the enclosing `#[@context]` fn's Anchor tree (enclosing Anchor `RootA`, requested type's Anchor `RootB`)
  ┌─ :6:23
  │
6 │     return @getContex(LeafB);
  │                       ^

  hint: Either provide the requested type under an Anchor reachable from the enclosing fn, or change the enclosing fn's `@Context<Base, …>` to share an Anchor with the requested type.

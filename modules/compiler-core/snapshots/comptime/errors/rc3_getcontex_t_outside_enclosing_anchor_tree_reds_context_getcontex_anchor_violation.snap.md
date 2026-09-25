----- SOURCE CODE
type RootA(name: string)
type RootB(name: string)
type LeafB(v: i32) implement @Context<RootB>
#[@use]
fn pickA() -> @Use<RootA, RootA> {
    return @getContex(LeafB);
}

----- ERROR
error: context-getcontex-anchor-violation: `@getContex(LeafB)` is outside the enclosing `#[@use]` fn's Anchor tree (enclosing Anchor `RootA`, requested type's Anchor `RootB`)
  ┌─ :6:23
  │
6 │     return @getContex(LeafB);
  │                       ^

  hint: Either provide the requested type under an Anchor reachable from the enclosing fn, or change the enclosing fn's `@Use<Base, …>` to share an Anchor with the requested type.

----- SOURCE CODE
type RootA(name: string)
type RootB(name: string)
type LeafB(v: i32) implement @Context<RootB>
#[@use]
fn pickA() -> @Use<RootA, RootA> {
    return @getContext(LeafB);
}

----- ERROR
error: context-getcontext-anchor-violation: `@getContext(LeafB)` is outside the enclosing `#[@use]` fn's Anchor tree (enclosing Anchor `RootA`, requested type's Anchor `RootB`)
  ┌─ :6:24
  │
6 │     return @getContext(LeafB);
  │                        ^

  hint: Either provide the requested type under an Anchor reachable from the enclosing fn, or change the enclosing fn's `@Use<Base, …>` to share an Anchor with the requested type.

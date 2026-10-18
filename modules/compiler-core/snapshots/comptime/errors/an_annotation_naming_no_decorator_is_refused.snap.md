----- SOURCE CODE
#[unknownMarker("anything", 1, 2, 3)]
type A(x: i32)

----- ERROR
error: annotation-not-a-decorator: `#[unknownMarker]` names nothing, not a decorator
  ┌─ main.bp:1:3
  │
1 │ #[unknownMarker("anything", 1, 2, 3)]
  │   ^

  hint: An annotation names a decorator — a `pub fn` whose first parameter is `comptime decl` of the declaration handle type — or an annotation type of your own; declare it, or delete the annotation.

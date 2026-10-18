----- SOURCE CODE
behavior Display {
    fn show(self: Self) -> string;
}
type Money(cents: i32) implement Display {
    declare fn show(self: Self) -> string;
}

----- ERROR
error: declare-without-implementation: `Money.show` is a bodyless `declare fn`, and no annotation implements it
  ┌─ main.bp:5:16
  │
5 │     declare fn show(self: Self) -> string;
  │                ^

  hint: Name its host code on each target: `#[@external(.Erlang("…"), .JavaScript("…"), .Wasm(…))]`, or give it a body (`fn`).

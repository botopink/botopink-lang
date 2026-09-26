----- SOURCE CODE
behavior Display {
    fn show(self: Self) -> string;
}
type Money(cents: i32) implement Display {
    declare fn show(self: Self) -> string;
}

----- ERROR
error: missing interface method
  ┌─ :4:6
  │
4 │ type Money(cents: i32) implement Display {
  │      ^

  'Money' does not implement 'show' required by behavior 'Display'

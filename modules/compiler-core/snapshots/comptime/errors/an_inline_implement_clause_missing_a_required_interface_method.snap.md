----- SOURCE CODE
behavior Display {
    fn show(self: Self) -> string;
}
type Money(cents: i32) implement Display { }

----- ERROR
error: missing interface method

  'Money' does not implement 'show' required by behavior 'Display'

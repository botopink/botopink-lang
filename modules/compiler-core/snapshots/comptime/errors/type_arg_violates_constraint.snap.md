----- SOURCE CODE
fn coerce(comptime v: type string | int | bool, x: i32) -> i32 {
    return x;
}
val bad = coerce(3.14, 0);

----- ERROR
error: type constraint not satisfied
  ┌─ :4:18
  │
4 │ val bad = coerce(3.14, 0);
  │                  ^

  'v' has type 'f64', which does not satisfy 'type string, int, bool'

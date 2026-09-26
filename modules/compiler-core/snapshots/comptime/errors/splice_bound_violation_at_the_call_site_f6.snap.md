----- SOURCE CODE
pub fn bad() -> @Expr<i32> {
    return @expr("not an int");
}
val d = bad();

----- ERROR
error: type mismatch
  ┌─ main.bp:4:9
  │
4 │ val d = bad();
  │         ^

  expected: i32
  found:    string

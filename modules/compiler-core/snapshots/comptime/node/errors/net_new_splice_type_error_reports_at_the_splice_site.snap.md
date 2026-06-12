----- SOURCE CODE
pub fn port() -> @Expr<i32> {
    return @expr(true);
}
val p = port();

----- ERROR
error: type mismatch
  ┌─ :4:9
  │
4 │ val p = port();
  │         ^

  expected: i32
  found:    bool

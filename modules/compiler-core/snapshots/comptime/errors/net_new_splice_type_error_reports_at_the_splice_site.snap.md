----- SOURCE CODE
pub fn port() -> @Expr<i32> {
    return @expr(true);
}
val p = port();

----- ERROR
error: template-build-outside-bound: `port` built code of type `bool`, outside its answer `i32`
  ┌─ main.bp:4:9
  │
4 │ val p = port();
  │         ^

  hint: A template's answer is a bound its built code fits (decision 426 (2)): build code of that type, or widen the answer.

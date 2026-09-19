----- SOURCE CODE
pub fn wrap(comptime template: @Expr<string>, prefix: string) -> @Expr<string> {
    return template;
}
val p = "pre:";
val c = wrap("hello", p);

----- ERROR
error: non-`@Expr` parameter of a template function must receive a literal value at the call site
  ┌─ :5:23
  │
5 │ val c = wrap("hello", p);
  │                       ^

  hint: Pass a string, integer, or boolean literal directly; runtime values have no compile-time meaning (V1).

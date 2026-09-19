----- SOURCE CODE
pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
    return template;
}
val tpl = "<p></p>";
val c = html(tpl);

----- ERROR
error: an `expr` argument must be a literal string at the call site
  ┌─ :5:14
  │
5 │ val c = html(tpl);
  │              ^

  hint: Write the template inline — `f """…"""` or `f("…")`; a variable carries no span or scope to capture (V1).

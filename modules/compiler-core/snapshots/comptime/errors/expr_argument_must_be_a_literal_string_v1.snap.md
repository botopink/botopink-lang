----- SOURCE CODE
pub fn html(expr template: string) -> string {
    return template;
}
val tpl = "<p></p>";
val c = html(tpl);

----- ERROR
error: expr-call-outside-expr: `html` is a template, called only with a template text, and is called here another way
  ┌─ main.bp:5:9
  │
5 │ val c = html(tpl);
  │         ^

  hint: Write its text after its name: `f @`select …``, `value.f @`…``, or `#[f @`…`]` (decision 577 (3)).

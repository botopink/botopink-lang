----- SOURCE CODE
pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
    return template;
}
val c = html """
<Buttom label="Send"/>
""";

----- ERROR
error: component `Buttom` not found in caller scope
  ┌─ main.bp:5:2
  │
5 │ <Buttom label="Send"/>
  │  ^

  hint: raised by the template function against this template (`fail`/`failAt`, or `lookup` of a name its text does not spell)

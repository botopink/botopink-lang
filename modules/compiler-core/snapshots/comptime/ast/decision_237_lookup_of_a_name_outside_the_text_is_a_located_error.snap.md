----- SOURCE CODE -- main.bp
```botopink
pub type Button(
    label: string,
)
pub fn need(comptime t: @Expr<string>) -> @Expr<string> {
    val hit = t.lookup("Button");
    if (hit) { b ->
        return t.build("\"hit\"");
    } else {
        return t.build("\"miss\"");
    };
}
val r = need "<Card/>";
```

----- COMPILE DIAGNOSTIC -- main
```text
error: lookup("Button"): not a word of the template's text; a template capture carries only the bindings whose name its text spells
  ┌─ main.bp:12:14
  │
12 │ val r = need "<Card/>";
  │              ^

  hint: raised by the template function against this template (`fail`/`failAt`, or `lookup` of a name its text does not spell)
```


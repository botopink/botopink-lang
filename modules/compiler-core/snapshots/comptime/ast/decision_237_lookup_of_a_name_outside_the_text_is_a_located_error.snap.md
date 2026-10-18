----- SOURCE CODE -- main.bp
```botopink
pub type Button(
    label: string,
)
pub fn need(syntax t: string) -> string {
    val hit = compiler.lookup(t, "Button");
    if (hit) { b ->
        return compiler.build("\"hit\"");
    } else {
        return compiler.build("\"miss\"");
    };
}
val r = need @`<Card/>`;

import {compiler} from "std";
```

----- COMPILE DIAGNOSTIC -- main
```text
error: lookup("Button"): not a word of the template's text; a template capture carries only the bindings whose name its text spells
  ┌─ main.bp:12:14
  │
12 │ val r = need @`<Card/>`;
  │              ^

  hint: raised by the template function against this template (`fail`/`failAt`, or `lookup` of a name its text does not spell)
```


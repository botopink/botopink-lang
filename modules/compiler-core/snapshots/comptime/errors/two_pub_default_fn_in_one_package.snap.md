----- SOURCE CODE
pub default fn one(syntax q: string) -> i32 { return compiler.build("0"); }
pub default fn two(syntax q: string) -> i32 { return compiler.build("0"); }
import {compiler} from "std";

----- ERROR
error: default-twice: a module has one default function
  ┌─ main.bp:2:16
  │
2 │ pub default fn two(syntax q: string) -> i32 { return compiler.build("0"); }
  │                ^

  hint: Keep one `pub default fn` (or `pub default <name>;`) per module (decision 289); the importer binds it under the module path.

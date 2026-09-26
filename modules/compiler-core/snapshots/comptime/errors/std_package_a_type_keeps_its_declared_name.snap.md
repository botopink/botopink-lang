----- SOURCE CODE
import {collections.Dict as D} from "std";

fn main() {
    val d: D<string, i32> = D(pairs: []);
}

----- ERROR
error: import-alias-on-type: `Dict` is a type; a type keeps its declared name
  ┌─ :1:9
  │
1 │ import {collections.Dict as D} from "std";
  │         ^

  hint: Import the type under its own name (`import {collections.Dict}`); `as` renames a value or a function.

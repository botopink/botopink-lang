----- SOURCE CODE
import {collections.Dict} from "std";

fn main() {
    val n = 1;
}

----- ERROR
error: unknown "std" module `collections` in import
  ┌─ :1:9
  │
1 │ import {collections.Dict} from "std";
  │         ^

  hint: Only the leaf of an import path enters scope; the segments before it name a std module (`libs/std/src/root.bp` lists them).

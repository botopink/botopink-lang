----- SOURCE CODE
import {collections: {Dict, emptyish}} from "std";

fn main() {
    val n = 1;
}

----- ERROR
error: std module `collections` has no public `emptyish`
  ┌─ :1:29
  │
1 │ import {collections: {Dict, emptyish}} from "std";
  │                             ^

  hint: Check the name against the module's `pub` declarations (`libs/std/AGENTS.md` lists each module's surface).

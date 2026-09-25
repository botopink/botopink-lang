----- SOURCE CODE
import {dict: {Dict, emptyish}} from "std";

fn main() {
    val n = 1;
}

----- ERROR
error: std module `dict` has no public `emptyish`
  ┌─ :1:22
  │
1 │ import {dict: {Dict, emptyish}} from "std";
  │                      ^

  hint: Check the name against the module's `pub` declarations (`libs/std/AGENTS.md` lists each module's surface).

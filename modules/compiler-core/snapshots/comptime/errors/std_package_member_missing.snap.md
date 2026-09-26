----- SOURCE CODE
import {collections} from "std";

fn main() {
    val x = collections.collapse(true);
}

----- ERROR
error: this "std" module has no such public function
  ┌─ :4:25
  │
4 │     val x = collections.collapse(true);
  │                         ^

  hint: Check the function name against the module's exports.

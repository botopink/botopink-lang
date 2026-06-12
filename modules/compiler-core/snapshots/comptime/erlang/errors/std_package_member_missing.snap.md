----- SOURCE CODE
import {order} from "std";

fn main() {
    val x = order.collapse(true);
}

----- ERROR
error: this "std" module has no such public function
  ┌─ :4:19
  │
4 │     val x = order.collapse(true);
  │                   ^

  hint: Check the function name against the module's exports.

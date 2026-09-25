----- SOURCE CODE
import {order.lt} from "std";

fn main() {
    val a = order.toInt(lt());
}

----- ERROR
error: unbound variable
  ┌─ :4:13
  │
4 │     val a = order.toInt(lt());
  │             ^

  'order' is not in scope

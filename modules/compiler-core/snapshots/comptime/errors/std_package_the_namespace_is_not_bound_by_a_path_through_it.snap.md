----- SOURCE CODE
import {collections.lt} from "std";

fn main() {
    val a = collections.toInt(lt());
}

----- ERROR
error: unbound variable
  ┌─ main.bp:4:13
  │
4 │     val a = collections.toInt(lt());
  │             ^

  'collections' is not in scope

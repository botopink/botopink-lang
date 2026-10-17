----- SOURCE CODE
pub fn hard(expr t: string) -> string {
    val x = compiler.text(t);
    return t;
}
val c = hard @`SELECT 1`;
import {compiler} from "std";

----- ERROR
error: cannot expand this template function at compile time
  ┌─ main.bp:5:9
  │
5 │ val c = hard @`SELECT 1`;
  │         ^

  hint: The V1 expansion driver supports bodies of the form `return <@Expr param>`, `return @expr(value)`, or `return @code("…")` with a literal string; richer bodies need the eval runtime (full `compile` pipeline).

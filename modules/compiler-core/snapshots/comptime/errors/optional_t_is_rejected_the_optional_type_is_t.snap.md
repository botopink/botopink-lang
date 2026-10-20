----- SOURCE CODE
fn takeOptional(x: @Optional<i32>) -> i32 {
    return x.unwrapOr(0);
}
fn main() -> void {
    print(takeOptional(3));
}

import {io.terminal.print} from "std";

----- ERROR
error: `@Option<T>` is not a type — the optional type is written `?T`
  ┌─ main.bp:1:20
  │
1 │ fn takeOptional(x: @Optional<i32>) -> i32 {
  │                    ^

  hint: Replace the annotation with `?T` (e.g. `?i32`).

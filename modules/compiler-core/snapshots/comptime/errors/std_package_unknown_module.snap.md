----- SOURCE CODE
import {linked_list} from "std";

----- ERROR
error: unknown "std" module in import
  ┌─ main.bp:1:9
  │
1 │ import {linked_list} from "std";
  │         ^

  hint: Available std modules: bool. (A `@Result`'s `map` / `flatMap` / `unwrapOr` / `isOk` / `isError` are its methods: `r.map(f)`, no import.)

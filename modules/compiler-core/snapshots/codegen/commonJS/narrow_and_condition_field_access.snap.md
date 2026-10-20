----- SOURCE CODE -- main.bp
```botopink
val Box = type(weight: i32)
fn describe(b: ?Box) -> string {
    if (b && b.weight > 10) {
        return "heavy";
    };
    return "light or none";
}
fn main() -> void {
    print(describe(Box(weight: 20)));
}

import {io.terminal.print} from "std";
```

----- COMPILE DIAGNOSTIC -- main
```text
error: type mismatch
  ┌─ main.bp:3:9
  │
3 │     if (b && b.weight > 10) {
  │         ^

  expected: bool
  found:    optional<Box>
```


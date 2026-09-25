----- SOURCE CODE -- std/probe.bp
```botopink
import {io: {clock: {nowMillis}}} from "std";

pub fn stamp() -> i32 {
    return nowMillis();
}
```

----- COMPILE DIAGNOSTIC -- std/probe
```text
error: std-root-imports-io: std module `probe` is at the root of std, which is pure; `io.clock.nowMillis` imports from `io/`
  ┌─ :1:22
  │
1 │ import {io: {clock: {nowMillis}}} from "std";
  │                      ^

  hint: Move the module under `io/` (it talks to the world), or take the value it needs as a parameter.
```


----- SOURCE CODE
#[@external(.Typescript("Math.max($args)", true))]
pub declare fn biggest(a: i32, b: i32) -> i32;

----- ERROR
error: `biggest` writes `result: true` on `.Typescript`, so it must return `@Result<…, HostError>` or `@Task<@Result<…, HostError>>`, not `i32`
  ┌─ main.bp:1:3
  │
1 │ #[@external(.Typescript("Math.max($args)", true))]
  │   ^

  hint: `result: true` turns every way the host fails into `Error(HostError(…))`, std's `failure.HostError` (`import {failure.HostError} from "std";`). Without the flag the binding promises no failure: delete it, or declare the `@Result`.

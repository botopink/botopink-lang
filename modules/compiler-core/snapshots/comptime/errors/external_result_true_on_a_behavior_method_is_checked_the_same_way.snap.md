----- SOURCE CODE
pub behavior Shape {
    #[@external(.JavaScript("area", result: true))]
    fn area(self: Self) -> i32;
}

----- ERROR
error: `area` writes `result: true` on `.JavaScript`, so it must return `@Result<…, HostError>` or `@Task<@Result<…, HostError>>`, not `i32`
  ┌─ main.bp:2:7
  │
2 │     #[@external(.JavaScript("area", result: true))]
  │       ^

  hint: `result: true` turns every way the host fails into `Error(HostError(…))`, std's `failure.HostError` (`import {failure.HostError} from "std";`). Without the flag the binding promises no failure: delete it, or declare the `@Result`.

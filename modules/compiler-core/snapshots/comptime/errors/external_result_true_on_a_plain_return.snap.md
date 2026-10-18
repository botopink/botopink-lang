----- SOURCE CODE
#[@external(.JavaScript("JSON.parse($0)", result: true))]
pub declare fn jsParse(s: string) -> i32;

----- ERROR
error: `jsParse` writes `result: true` on `.JavaScript`, so it must return `@Result<…, HostError>` or `@Task<@Result<…, HostError>>`, not `i32`
  ┌─ main.bp:1:3
  │
1 │ #[@external(.JavaScript("JSON.parse($0)", result: true))]
  │   ^

  hint: `result: true` turns every way the host fails into `Error(HostError(…))`, std's `failure.HostError` (`import {failure.HostError} from "std";`). Without the flag the binding promises no failure: delete it, or declare the `@Result`.

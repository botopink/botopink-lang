----- SOURCE CODE
#[@External.Erlang("timer:sleep($0)", result: true)]
pub declare fn pause(ms: i32) -> @Task<i32>;

----- ERROR
error: `pause` writes `result: true` on `External.Erlang`, so it must return `@Result<…, HostError>` or `@Task<@Result<…, HostError>>`, not `@Task<i32>`
  ┌─ main.bp:1:3
  │
1 │ #[@External.Erlang("timer:sleep($0)", result: true)]
  │   ^

  hint: `result: true` turns every way the host fails into `Error(HostError(…))`, std's `failure.HostError` (`import {failure.HostError} from "std";`). Without the flag the binding promises no failure: delete it, or declare the `@Result`.

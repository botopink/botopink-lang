----- SOURCE CODE
#[compiler.external(.Erlang("timer:sleep($0)", result: true))]
pub declare fn pause(ms: i32) -> Async<i32>;

import {compiler} from "std";

----- ERROR
error: `pause` writes `result: true` on `.Erlang`, so it must return `Result<…, HostError>` or `Async<Result<…, HostError>>`, not `Async<i32>`
  ┌─ main.bp:1:3
  │
1 │ #[compiler.external(.Erlang("timer:sleep($0)", result: true))]
  │   ^

  hint: `result: true` turns every way the host fails into `Error(HostError(…))`, std's `failure.HostError` (`import {failure.HostError} from "std";`). Without the flag the binding promises no failure: delete it, or declare the `Result`.

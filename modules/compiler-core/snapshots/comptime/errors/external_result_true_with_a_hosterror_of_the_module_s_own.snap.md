----- SOURCE CODE
pub type HostError(message: string)

#[@external(.JavaScript("JSON.parse($0)", result: true))]
pub declare fn jsParse(s: string) -> @Result<i32, HostError>;

----- ERROR
error: `jsParse` writes `result: true` on `.JavaScript`, and its `HostError` is not std's `failure.HostError` — only std's counts, by module identity (decision 488)
  ┌─ main.bp:3:3
  │
3 │ #[@external(.JavaScript("JSON.parse($0)", result: true))]
  │   ^

  hint: Import std's: `import {failure.HostError} from "std";`, and name the module's own type otherwise.

----- SOURCE CODE
#[@External.Node("JSON.parse($0)", result: 1)]
pub declare fn jsParse(s: string) -> i32;

----- ERROR
error: `External.Node`'s `result` is a bool, got `1`
  ┌─ main.bp:1:3
  │
1 │ #[@External.Node("JSON.parse($0)", result: 1)]
  │   ^

  hint: Write `result: true` or `result: false`.

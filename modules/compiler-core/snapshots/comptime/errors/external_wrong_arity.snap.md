----- SOURCE CODE
#[@External.Erlang(..)]
pub declare fn str_length(s: string) -> i32;

----- ERROR
error: `@external` module and symbol must be string literals
  ┌─ :1:3
  │
1 │ #[@External.Erlang(..)]
  │   ^

  hint: Example: #[@External.Node("./gleam_stdlib.mjs", "string_length")]

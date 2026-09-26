----- SOURCE CODE
#[@External.Python("string", "length")]
pub declare fn str_length(s: string) -> i32;

----- ERROR
error: `@external` target must be a Target member: node, typescript, erlang, beam or wasm
  ┌─ :1:3
  │
1 │ #[@External.Python("string", "length")]
  │   ^

  hint: Example: #[@External.Erlang( "string", "length")]

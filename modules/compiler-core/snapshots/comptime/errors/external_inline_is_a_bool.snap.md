----- SOURCE CODE
#[@External.Erlang("max($args)", inline: 1)]
pub declare fn biggest(a: i32, b: i32) -> i32;

----- ERROR
error: `External.Erlang`'s `inline` is a bool, got `1`
  ┌─ main.bp:1:3
  │
1 │ #[@External.Erlang("max($args)", inline: 1)]
  │   ^

  hint: Write `inline: true` or `inline: false`.

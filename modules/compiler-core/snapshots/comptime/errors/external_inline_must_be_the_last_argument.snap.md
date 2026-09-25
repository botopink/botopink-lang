----- SOURCE CODE
#[@External.Erlang(inline = true, "max($args)")]
pub declare fn biggest(a: i32, b: i32) -> i32;

----- ERROR
error: `External.Erlang`'s `inline` must be the last argument — the emitters read the last argument only
  ┌─ :1:3
  │
1 │ #[@External.Erlang(inline = true, "max($args)")]
  │   ^

  hint: Write the template first: `#[@External.Erlang("<template>", inline = true)]`.

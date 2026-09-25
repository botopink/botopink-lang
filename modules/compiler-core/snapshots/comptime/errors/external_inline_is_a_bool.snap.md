----- SOURCE CODE
#[@External.Beam("max($args)", inline = 1)]
pub declare fn biggest(a: i32, b: i32) -> i32;

----- ERROR
error: `External.Beam`'s `inline` is a bool, got `1`
  ┌─ :1:3
  │
1 │ #[@External.Beam("max($args)", inline = 1)]
  │   ^

  hint: Write `inline = true` or `inline = false`.

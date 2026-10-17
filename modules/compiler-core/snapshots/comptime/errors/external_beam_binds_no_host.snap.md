----- SOURCE CODE
#[@External.Beam("math", "sqrt")]
pub declare fn root(x: f64) -> f64;

----- ERROR
error: `@External.Beam` binds no host — the beam target reads `@External.Erlang`
  ┌─ main.bp:1:3
  │
1 │ #[@External.Beam("math", "sqrt")]
  │   ^

  hint: Write `#[@External.Erlang("<module>", "<function>")]`; the beam target reads it too.

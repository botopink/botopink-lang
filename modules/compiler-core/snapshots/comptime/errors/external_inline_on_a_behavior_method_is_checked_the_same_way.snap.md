----- SOURCE CODE
pub behavior Shape {
    #[@External.Wasm("area", inline = true)]
    fn area(self: Self) -> i32;
}

----- ERROR
error: `External.Wasm` declares no `inline` — the flag is read by the erlang and beam emitters only
  ┌─ main.bp:2:7
  │
2 │     #[@External.Wasm("area", inline = true)]
  │       ^

  hint: Delete it: on `External.Wasm` `inline` is a switch nothing reads. `External.Erlang` and `External.Beam` declare it (`builtins.d.bp`).

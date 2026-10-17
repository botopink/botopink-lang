----- SOURCE CODE
pub behavior Shape {
    #[@external(.Wasm("area", inline: true))]
    fn area(self: Self) -> i32;
}

----- ERROR
error: `Implementation.Wasm` has no parameter named `inline`
  ┌─ main.bp:2:22
  │
2 │     #[@external(.Wasm("area", inline: true))]
  │                      ^

  hint: A label names the parameter its argument fills.

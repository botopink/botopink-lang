----- SOURCE CODE
type Token {
    Color {
        Red { 100, 500 }
    }
}
type Border {
    Color {
        Red { 100, 500 }
    }
}
val x = .Color.Red.500;

----- ERROR
error: the path ".Color.Red.500" is carried by more than one enum — "Border" and "Token" — and nothing here says which (ES5 — enum-sections path ambiguity)
  ┌─ :11:9
  │
11 │ val x = .Color.Red.500;
  │         ^

  hint: Give the position a type the path can be read against — a `val` annotation, a declared parameter, the function's return type.

----- SOURCE CODE
type Token {
    Color {
        Red { 500 }
    }
}
fn pick() -> Token {
    return .Color.Bogus.500;
}

----- ERROR
error: enum "Token" has no path ".Color.Bogus.500" (ES4 — enum-sections path resolution)
  ┌─ main.bp:7:19
  │
7 │     return .Color.Bogus.500;
  │                   ^

  hint: Check the section/variant chain against the enum declaration's `sections` tree; numeric leaves are matched under their declared digit form (`.Color.Red.500`).

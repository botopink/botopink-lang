----- SOURCE CODE
type Shape { Circle(radius: i32), Rect(width: i32, height: i32) }
fn radiusOf(s: Shape) -> i32 {
    val assert Circle(r) = s catch Shape.Rect(1, 1);
    return r;
}

----- ERROR
error: assert-catch-never-matches: after `catch` the value stands for the subject, and `Shape.Rect` never matches the pattern `Circle`
  ┌─ main.bp:3:42
  │
3 │     val assert Circle(r) = s catch Shape.Rect(1, 1);
  │                                          ^

  hint: The value after `catch` is matched against the pattern again: a constructor of another variant always fails, and a failure is fatal. Build the variant the pattern names, or leave with `catch return …` / `catch throw …` (decision 1057).

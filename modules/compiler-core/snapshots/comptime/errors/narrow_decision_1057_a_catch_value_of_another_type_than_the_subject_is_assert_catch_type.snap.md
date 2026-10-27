----- SOURCE CODE
type Shape { Circle(radius: i32), Rect(width: i32, height: i32) }
fn radiusOf(s: Shape) -> i32 {
    val assert Circle(r) = s catch -1;
    return r;
}

----- ERROR
error: assert-catch-type: after `catch` the value stands for the subject: `Shape` expected, `i32` written
  ┌─ main.bp:3:36
  │
3 │     val assert Circle(r) = s catch -1;
  │                                    ^

  hint: When the subject does not match, the value after `catch` is matched against the pattern again, so it has the subject's type. To leave instead, write a jump: `catch return …` or `catch throw …` (decision 1057).

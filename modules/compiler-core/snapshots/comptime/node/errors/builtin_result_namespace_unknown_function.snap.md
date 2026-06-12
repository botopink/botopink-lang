----- SOURCE CODE
*fn parse(n: i32) -> @Result<i32, string> {
    return n;
}

fn main() {
    val x = result.collapse(parse(1));
}

----- ERROR
error: unknown `result` namespace function
  ┌─ :6:20
  │
6 │     val x = result.collapse(parse(1));
  │                    ^

  hint: Available: map, then, unwrap, isOk, isError.

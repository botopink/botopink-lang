----- SOURCE CODE
#[@result]
fn parse(n: i32) -> @Result<i32, string> {
    return n;
}

fn main() {
    val x = result.collapse(parse(1));
}

----- ERROR
error: unknown `result` namespace function
  ┌─ :7:20
  │
7 │     val x = result.collapse(parse(1));
  │                    ^

  hint: Available: map, then, unwrap, isOk, isError.

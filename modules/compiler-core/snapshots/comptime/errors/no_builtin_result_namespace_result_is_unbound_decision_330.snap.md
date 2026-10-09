----- SOURCE CODE
fn parse(n: i32) -> @Result<i32, string> {
    return n;
}

fn main() {
    val x = result.collapse(parse(1));
}

----- ERROR
error: unbound variable
  ┌─ main.bp:6:13
  │
6 │     val x = result.collapse(parse(1));
  │             ^

  'result' is not in scope

----- SOURCE CODE
fn count(xs: string[]) -> i32 {
    val items = iter for (xs) { x ->
        if (x == "stop") { throw "stopped"; };
        yield 1;
    };
    var acc = 0;
    for (items) { r -> acc = acc + r; };
    return acc;
}

----- ERROR
error: type mismatch
  ┌─ main.bp:7:36
  │
7 │     for (items) { r -> acc = acc + r; };
  │                                    ^

  expected: i32
  found:    Result<i32,string>
  hint: a `for` over a sequence of `@Result`s hands over each item as the `@Result` (no implicit `try`): write `try r` to propagate its error, or handle it with `case` / `catch`; it is a `@Result` because of the `throw` at 3:28 in its own block

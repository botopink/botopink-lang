----- SOURCE CODE
fn upTo(n: i32) -> @Iterator<@Result<i32, string>> {
    yield n;
}
fn total(n: i32) -> i32 {
    var acc = 0;
    for (upTo(n)) { x -> acc = acc + x; };
    return acc;
}

----- ERROR
error: type mismatch

  expected: i32
  found:    Result<i32,string>
  hint: a `@Result` stands where its value is expected: propagate it with `try` (`try await t` for a Task, `try r` for a `for` item) or handle it with `case` / `catch`; a value inferred as `@Result` became one from a `throw` / `try` in its own block

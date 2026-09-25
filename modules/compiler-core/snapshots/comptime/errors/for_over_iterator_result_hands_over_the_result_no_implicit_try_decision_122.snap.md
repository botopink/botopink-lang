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

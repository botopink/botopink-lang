----- SOURCE CODE
test "bad assert" {
    assert 42;
}

----- ERROR
error: type mismatch
  ┌─ :2:12
  │
2 │     assert 42;
  │            ^

  expected: bool
  found:    i32

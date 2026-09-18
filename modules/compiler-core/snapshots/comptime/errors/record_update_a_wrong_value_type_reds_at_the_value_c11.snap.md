----- SOURCE CODE
type Person(name: string, age: i32)
val alice = Person(name: "a", age: 1);
val b = Person(..alice, age: "x");

----- ERROR
error: type mismatch
  ┌─ :3:30
  │
3 │ val b = Person(..alice, age: "x");
  │                              ^

  expected: i32
  found:    string

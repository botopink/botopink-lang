----- SOURCE CODE
val Person = type(
    name: string,
    age: i32,
);
val alice = Person(name: "Alice", age: 30);
val bob = Person(..alice, age: "thirty");

----- ERROR
error: type mismatch
  ┌─ main.bp:6:32
  │
6 │ val bob = Person(..alice, age: "thirty");
  │                                ^

  expected: i32
  found:    string

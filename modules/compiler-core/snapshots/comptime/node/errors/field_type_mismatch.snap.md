----- SOURCE CODE
val Person = record {
    name: string,
    age: i32,
};
val alice = Person(name: "Alice", age: 30);
val bob = Person(..alice, age: "thirty");

----- ERROR
error: type mismatch
  ┌─ :6:20
  │
6 │ val bob = Person(..alice, age: "thirty");
  │                    ^

  expected: string
  found:    Person

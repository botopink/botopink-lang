----- SOURCE CODE
val Person = record {
    name: string,
    age: i32,
};
val alice = Person(name: "Alice", age: 30);
val bob = Person(..alice, nickname: "Bobby");

----- ERROR
error: type mismatch
  ┌─ :6:20
  │
6 │ val bob = Person(..alice, nickname: "Bobby");
  │                    ^

  expected: string
  found:    Person

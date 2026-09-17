----- SOURCE CODE
val Person = type(
    name: string,
    age: i32,
);
val alice = Person(name: "Alice", age: 30);
val bob = Person(..alice, nickname: "Bobby");

----- ERROR
error: unknown field
  ┌─ :6:27
  │
6 │ val bob = Person(..alice, nickname: "Bobby");
  │                           ^

  'Person' has no field 'nickname'

----- SOURCE CODE
val Subject = enum {
    Person(name: string, age: i32),
    Animal(species: string),
};
val alice = Subject.Person(name: "Alice", age: 30);
val dog = Subject.Animal(..alice);

----- ERROR
error: type mismatch
  ┌─ :6:28
  │
6 │ val dog = Subject.Animal(..alice);
  │                            ^

  expected: string
  found:    Subject

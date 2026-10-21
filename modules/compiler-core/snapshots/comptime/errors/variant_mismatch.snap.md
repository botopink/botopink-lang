----- SOURCE CODE
val Subject = type {
    Person(name: string, age: i32),
    Animal(species: string),
};
val alice = Subject.Person(name: "Alice", age: 30);
val dog = Subject.Animal(..alice);

----- ERROR
error: call-spread: `this call` constructs no record — a spread copies a record's fields into its constructor, and a function call takes none
  ┌─ main.bp:6:26
  │
6 │ val dog = Subject.Animal(..alice);
  │                          ^

  hint: Pass the arguments one by one; a function that takes an existing array declares `values: T[]` (decision 267).

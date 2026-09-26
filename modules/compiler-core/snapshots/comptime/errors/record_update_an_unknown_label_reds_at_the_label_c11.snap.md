----- SOURCE CODE
type Person(name: string, age: i32)
val alice = Person(name: "a", age: 1);
val b = Person(..alice, agee: 25);

----- ERROR
error: unknown field
  ┌─ main.bp:3:25
  │
3 │ val b = Person(..alice, agee: 25);
  │                         ^

  'Person' has no field 'agee'

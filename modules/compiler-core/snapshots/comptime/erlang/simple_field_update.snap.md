----- SOURCE CODE -- main.bp
```botopink
val Person = record {
    name: string,
    age: i32,
    city: string,
};
val alice = Person(name: "Alice", age: 30, city: "London");
val bob = Person(..alice, name: "Bob", age: 25);
```


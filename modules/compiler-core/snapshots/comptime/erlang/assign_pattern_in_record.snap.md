----- SOURCE CODE -- main.bp
```botopink
val Person = record {
    name: string,
    age: i32,
};
val describe = fn(p: Person) -> string {
    case p {
        Person(name, age) as person -> name + " is " + age;
    };
};
```

----- COMPILE DIAGNOSTIC -- main
```text
error: parse error (unexpectedToken)
  ┌─ :7:27
  │
7 │         Person(name, age) as person -> name + " is " + age;

  unexpected `as`
```


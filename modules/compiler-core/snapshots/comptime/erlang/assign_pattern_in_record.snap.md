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


----- SOURCE CODE -- main.bp
```botopink
record Person { name: string, age: i32 }
fn greet({ name, age }: Person) -> string {
    return name;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(Person, {name, age}).

greet() ->
    Name.
```

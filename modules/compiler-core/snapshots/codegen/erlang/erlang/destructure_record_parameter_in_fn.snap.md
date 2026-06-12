----- SOURCE CODE -- main.bp
```botopink
record Person { name: string, age: i32 }
fn greet({ name, .. }: Person) -> string {
    @print(name);
    return name;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record Person: name, age

greet({Name, _}) ->
    io:format("~p~n", [Name]),
    Name.
```

----- RUN LOG -----
```logs
```

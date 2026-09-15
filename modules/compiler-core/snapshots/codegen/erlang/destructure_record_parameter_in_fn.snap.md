----- SOURCE CODE -- main.bp
```botopink
record Person { name: string, age: i32 }
fn greet({ name, .. }: Person) -> string {
    @print(name);
    return name;
}
fn main() {
    greet(Person(name: "Ana", age: 30));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% record Person: name, age

greet({Name, _}) ->
    io:format("~p~n", [Name]),
    Name.

main() ->
    greet(#{name => <<"Ana">>, age => 30}).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

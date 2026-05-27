----- SOURCE CODE -- main.bp
```botopink
fn fetch() -> i32 {
    @todo();
}
fn process() -> i32 {
    val r = try fetch();
    @print(r);
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

fetch() ->
    erlang:error({todo, "not implemented"}).

process() ->
    R = fetch(),
    io:format("~p~n", [R]),
    R.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
pub fn port<T>() -> @Expr<T> {
    return @code("8080");
}
fn main() {
    val p = port() + 1;
    @print(p);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    P = (8080 + 1),
    io:format("~p~n", [P]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
8081
```

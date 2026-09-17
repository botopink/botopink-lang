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
    '__bp_print'([P]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
8081
```

----- SOURCE CODE -- main.bp
```botopink
fn negate(v: bool) -> bool {
    return !v;
}
fn main() {
    @print(negate(true));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

negate(V) ->
    (not V).

main() ->
    io:format("~p~n", [negate(true)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
false
```

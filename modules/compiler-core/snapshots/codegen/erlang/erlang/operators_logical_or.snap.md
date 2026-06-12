----- SOURCE CODE -- main.bp
```botopink
fn either(a: bool, b: bool) -> bool {
    return a || b;
}
fn main() {
    @print(either(false, true));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

either(A, B) ->
    (A or B).

main() ->
    io:format("~p~n", [either(false, true)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
true
```

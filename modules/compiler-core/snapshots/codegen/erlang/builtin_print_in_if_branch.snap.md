----- SOURCE CODE -- main.bp
```botopink
fn check(x: i32) {
    if (x > 0) {
        @print("positive");
    } else {
        @print("non-positive");
    }
}
fn main() {
    check(1);
    check(-1);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

check(X) ->
    case (X > 0) of
        true ->
            io:format("~p~n", [<<"positive">>]);
        false ->
            io:format("~p~n", [<<"non-positive">>])
    end.

main() ->
    check(1),
    check((-1)).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<<"positive">>
<<"non-positive">>
```

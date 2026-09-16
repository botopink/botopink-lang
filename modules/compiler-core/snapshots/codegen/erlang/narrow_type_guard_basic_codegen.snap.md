----- SOURCE CODE -- main.bp
```botopink
fn isPositive(n: i32) -> n is i32 {
    return n > 0;
}
fn main() {
    @print(isPositive(5));
    @print(isPositive(-5));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

isPositive(N) ->
    (N > 0).

main() ->
    io:format("~p~n", [isPositive(5)]),
    io:format("~p~n", [isPositive((-5))]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
true
false
```

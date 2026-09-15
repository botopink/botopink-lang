----- SOURCE CODE -- main.bp
```botopink
fn isZero(n: i32) -> bool {
    return n == 0;
}
fn main() {
    @print(isZero(0));
    @print(isZero(42));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

isZero(N) ->
    (N =:= 0).

main() ->
    io:format("~p~n", [isZero(0)]),
    io:format("~p~n", [isZero(42)]).

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

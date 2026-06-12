----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val n = -5;
    @print(n.abs());
    @print(n.min(3));
    @print(n.max(10));
    @print(n.clamp(0, 5));
    val x = 7;
    @print(x.isEven());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% interface Number

%% interface Signed

%% interface Integer

main() ->
    N = (-5),
    io:format("~p~n", [abs(N)]),
    io:format("~p~n", [min(N, 3)]),
    io:format("~p~n", [max(N, 10)]),
    io:format("~p~n", [clamp(N, 0, 5)]),
    X = 7,
    io:format("~p~n", [isEven(X)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

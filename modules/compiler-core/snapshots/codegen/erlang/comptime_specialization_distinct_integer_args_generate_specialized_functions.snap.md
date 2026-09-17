----- SOURCE CODE -- main.bp
```botopink
fn multiply(comptime factor: i32, x: i32) -> i32 {
    return x * factor;
}

fn main() {
    val double = multiply(2, 21);
    val triple = multiply(3, 21);
    val doubleAgain = multiply(2, 10);
    @print(double);
    @print(triple);
    @print(doubleAgain);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    Double = 'multiply_$0'(21),
    Triple = 'multiply_$1'(21),
    DoubleAgain = 'multiply_$0'(10),
    io:format("~p~n", [Double]),
    io:format("~p~n", [Triple]),
    io:format("~p~n", [DoubleAgain]).

'multiply_$0'(X) ->
    Factor = 2,
    (X * Factor).

'multiply_$1'(X) ->
    Factor = 3,
    (X * Factor).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
42
63
20
```

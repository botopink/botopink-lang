----- SOURCE CODE -- main.bp
```botopink
fn multiply(comptime factor: i32, x: i32) -> i32 {
    return x * factor;
}

fn calculate() {
    val double = multiply(2, 21);
    val triple = multiply(3, 21);
    val doubleAgain = multiply(2, 10);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

calculate() ->
    Double = multiply_$0(21),
    Triple = multiply_$1(21),
    DoubleAgain = multiply_$0(10).

multiply_$0(X) ->
    Factor = 2,
    (X * Factor).

multiply_$1(X) ->
    Factor = 3,
    (X * Factor).
```

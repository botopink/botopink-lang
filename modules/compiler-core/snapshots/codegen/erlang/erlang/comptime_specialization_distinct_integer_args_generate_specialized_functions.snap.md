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

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

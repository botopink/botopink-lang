----- SOURCE CODE -- main.bp
```botopink
fn sumTo(n: i32) -> i32 {
    return loop (0..n) { i ->
        yield i;
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

sumTo(N) ->
    lists:map(fun(I) ->
        I
    end, lists:seq(0, N)).
```

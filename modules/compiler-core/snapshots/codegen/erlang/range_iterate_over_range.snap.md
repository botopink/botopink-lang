----- SOURCE CODE -- main.bp
```botopink
fn sumTo(n: i32) -> i32 {
    var sum = 0;
    for (0..n) { i ->
        sum = sum + i;
    };
    return sum;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

sumTo(N) ->
    Sum = 0,
    Sum@3 = lists:foldl(fun(I, Sum@1) ->
        Sum@2 = (Sum@1 + I),
        Sum@2
    end, Sum, lists:seq(0, (N) - 1)),
    Sum@3.
```

----- RUN LOG -----
```logs
```

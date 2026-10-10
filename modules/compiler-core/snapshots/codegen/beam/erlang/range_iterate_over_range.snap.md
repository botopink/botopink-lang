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
        Sum@2 = '__bp_int'((Sum@1 + I), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:4:19">>),
        Sum@2
    end, Sum, lists:seq(0, (N) - 1)),
    Sum@3.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).
```

----- RUN LOG -----
```logs
```

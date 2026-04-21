----- SOURCE CODE -- main.bp
```botopink
fn abs(n: i32) -> i32 {
    val result = if (n < 0) -n else n;
    return result;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

abs(N) ->
    Result = case (N < 0) of
        true ->
            (-N);
        false ->
            N
    end,
    Result.
```

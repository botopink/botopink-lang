----- SOURCE CODE -- main.bp
```botopink
fn doubles(arr: i32[]) -> i32[] {
    return loop (arr) { x ->
        yield x * 2;
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

doubles(Arr) ->
    lists:map(fun(X) ->
        (X * 2)
    end, Arr).
```

----- SOURCE CODE -- main.bp
```botopink
fn sumEvens(arr: i32[]) -> i32 {
    return loop (arr) { x ->
        if (x % 2 != 0) { continue; };
        yield x;
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

sumEvens(Arr) ->
    lists:map(fun(X) ->
        case ((X rem 2) =/= 0) of
            true ->
                %% continue
        end,
        X
    end, Arr).
```

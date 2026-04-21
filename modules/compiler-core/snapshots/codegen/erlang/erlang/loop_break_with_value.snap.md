----- SOURCE CODE -- main.bp
```botopink
fn find(arr: i32[]) -> i32 {
    return loop (arr) { x ->
        if (x > 10) { break x; };
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

find(Arr) ->
    lists:foreach(fun(X) ->
        case (X > 10) of
            true ->
                X
        end
    end, Arr).
```

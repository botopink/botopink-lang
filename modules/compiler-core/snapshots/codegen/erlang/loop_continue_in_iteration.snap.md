----- SOURCE CODE -- main.bp
```botopink
fn sumEvens(arr: i32[]) -> i32[] {
    var out = [];
    for (arr) { x ->
        if (x % 2 != 0) { continue; };
        out.push(x);
    };
    return out;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

sumEvens(Arr) ->
    Out = [],
    Out@3 = lists:foldl(fun(X, Out@1) ->
        case ((X rem 2) =/= 0) of
            true ->
                %% continue;
            _ -> ok
        end,
        Out@2 = (Out@1 ++ [X]),
        Out@2
    end, Out, Arr),
    Out@3.
```

----- RUN LOG -----
```logs
```

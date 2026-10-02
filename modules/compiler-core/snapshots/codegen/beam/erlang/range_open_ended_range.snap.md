----- SOURCE CODE -- main.bp
```botopink
fn countUp(x: i32) {
    for (x..) { i ->
        if (i > 100) {
          break;
        };
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

countUp(X) ->
    try
        (fun __BpLoop(I) ->
            case (I > 100) of
                true ->
                    erlang:throw('__bp_break');
                _ -> ok
            end,
            __BpLoop(I + 1)
        end)(X)
    catch
        throw:'__bp_break' -> ok
    end.
```

----- RUN LOG -----
```logs
```

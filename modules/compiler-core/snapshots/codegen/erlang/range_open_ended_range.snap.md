----- SOURCE CODE -- main.bp
```botopink
fn countUp(x: i32) -> void {
    for i in x.. {
        if (i > 100) {
          break;
        };
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__countUp'/1]).

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

'__bp_priv__countUp'(A0) -> countUp(A0).
```

----- RUN LOG -----
```logs
```

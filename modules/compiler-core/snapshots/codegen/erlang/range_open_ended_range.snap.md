----- SOURCE CODE -- main.bp
```botopink
fn countUp(x: i32) -> void {
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
-export(['__bp_priv__countUp'/1]).

countUp(X) ->
    try
        (fun __BpLoop() ->
            __for2_5_c0 = X,
            __for2_5_c0@3 = try
                (fun __BpLoop1(__for2_5_c0@1) ->
                    I = __for2_5_c0@1,
                    __for2_5_c0@2 = '__bp_int'((__for2_5_c0@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:2:11">>),
                    case (I > 100) of
                        true ->
                            erlang:throw({'__bp_cond_break', __for2_5_c0@2});
                        _ -> ok
                    end,
                    __BpLoop1(__for2_5_c0@2)
                end)(__for2_5_c0)
            catch
                throw:{'__bp_cond_break', __BpGroup2} -> __BpGroup2
            end,
            erlang:throw({'__bp_cond_break', ok}),
            __BpLoop()
        end)()
    catch
        throw:{'__bp_cond_break', __BpGroup1} -> __BpGroup1
    end.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_priv__countUp'(A0) -> countUp(A0).
```

----- RUN LOG -----
```logs
```

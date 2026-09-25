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
    Out@3 = (fun __Loop(__BpIter1, Out@1) ->
        case __BpIter1 of
            [X | __BpRest1] ->
                __Loop(__BpRest1, try
                    case ((X rem 2) =/= 0) of
                        true ->
                            erlang:throw({'__bp_cond_continue', Out@1});
                        _ -> ok
                    end,
                    Out@2 = (Out@1 ++ [X]),
                    Out@2
                catch
                    throw:{'__bp_cond_continue', __BpGroup1} -> __BpGroup1
                end);
            _ -> Out@1
        end
    end)(Arr, Out),
    Out@3.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
fn process(x: i32) -> string {
    return case (x) {
        0 -> {
            case (x) {
                0 -> "zero";
                _ -> "other";
            }
        };
        _ -> "non-zero";
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__process'/1]).

process(X) ->
    case X of
        0 ->
            case X of
                0 ->
                    <<"zero">>;
                _ ->
                    <<"other">>
            end;
        _ ->
            <<"non-zero">>
    end.

'__bp_priv__process'(A0) -> process(A0).
```

----- RUN LOG -----
```logs
```

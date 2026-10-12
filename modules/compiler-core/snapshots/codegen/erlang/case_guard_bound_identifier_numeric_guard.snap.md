----- SOURCE CODE -- main.bp
```botopink
fn classify(n: i32) -> string {
    return case n {
        x if x > 0 -> "positive";
        0 -> "zero";
        _ -> "negative";
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__classify'/1]).

classify(N) ->
    case N of
        X when (X > 0) ->
            <<"positive">>;
        0 ->
            <<"zero">>;
        _ ->
            <<"negative">>
    end.

'__bp_priv__classify'(A0) -> classify(A0).
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
fn process(a: i32, b: i32) {
    case a, b {
        0, 0 -> null;
        _, _ -> null;
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__process'/2]).

process(A, B) ->
    case {A, B} of
        {0, 0} ->
            undefined;
        {_, _} ->
            undefined
    end.

'__bp_priv__process'(A0, A1) -> process(A0, A1).
```

----- RUN LOG -----
```logs
```

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
-module(main).

process(A, B) ->
    case {A, B} of
        {0, 0} ->
            undefined;
        {_, _} ->
            undefined
    end.
```

----- SOURCE CODE -- main.bp
```botopink
fn describe(n: i32) -> string {
    return if (n > 0) { "positive"; } else { "non-positive"; };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

describe(N) ->
    case (N > 0) of
        true ->
            <<"positive">>;
        false ->
            <<"non-positive">>
    end.
```

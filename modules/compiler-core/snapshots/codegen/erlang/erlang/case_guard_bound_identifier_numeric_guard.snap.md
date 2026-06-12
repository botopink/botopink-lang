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
-module(main).

classify(N) ->
    case N of
        X ->
            <<"positive">>;
        0 ->
            <<"zero">>;
        _ ->
            <<"negative">>
    end.
```

----- RUN LOG -----
```logs
```

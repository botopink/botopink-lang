----- SOURCE CODE -- main.bp
```botopink
fn classify(n: i32) -> string {
    val result = case n {
        0 -> "zero";
        1 -> "one";
        _ -> "many";
    };
    @print(result);
    return result;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

classify(N) ->
    Result = case N of
        0 ->
            <<"zero">>;
        1 ->
            <<"one">>;
        _ ->
            <<"many">>
    end,
    io:format("~p~n", [Result]),
    Result.
```

----- RUN LOG -----
```logs
```

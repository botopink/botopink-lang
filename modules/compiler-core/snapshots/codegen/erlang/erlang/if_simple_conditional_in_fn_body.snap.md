----- SOURCE CODE -- main.bp
```botopink
fn sign(n: i32) -> string {
    val r = if (n > 0) { "positive"; };
    @print(r);
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

sign(N) ->
    R = case (N > 0) of
        true ->
            <<"positive">>;
        _ -> ok
    end,
    io:format("~p~n", [R]),
    R.
```

----- RUN LOG -----
```logs
```

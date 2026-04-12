----- SOURCE CODE -- main.bp
```botopink
fn sign(n: i32) -> string {
    val r = if (n > 0) { "positive"; };
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

sign(N) ->
    R = case (N > 0) of
        true ->
            <<"positive">>
    end,
    R.
```

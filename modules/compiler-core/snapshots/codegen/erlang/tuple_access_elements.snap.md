----- SOURCE CODE -- main.bp
```botopink
fn getFirst(t: #(i32, string)) -> i32 {
    return t._0;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__getFirst'/1]).

getFirst(T) ->
    erlang:element(1, T).

'__bp_priv__getFirst'(A0) -> getFirst(A0).
```

----- RUN LOG -----
```logs
```

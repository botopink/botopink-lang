----- SOURCE CODE -- main.bp
```botopink
fn getFirst(t: #(i32, string)) -> i32 {
    return t._0;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

getFirst(T) ->
    element(1, T).
```

----- RUN LOG -----
```logs
```

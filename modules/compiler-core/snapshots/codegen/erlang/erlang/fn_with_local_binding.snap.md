----- SOURCE CODE -- main.bp
```botopink
fn double(x: i32) -> i32 {
    val result = x * 2;
    return result;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

double(X) ->
    Result = (X * 2),
    Result.
```

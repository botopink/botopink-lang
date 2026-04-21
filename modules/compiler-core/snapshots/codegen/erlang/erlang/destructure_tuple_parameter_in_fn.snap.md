----- SOURCE CODE -- main.bp
```botopink
fn process(#(x, y): #(i32, i32)) -> i32 {
    return x;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

process({X, Y}) ->
    X.
```

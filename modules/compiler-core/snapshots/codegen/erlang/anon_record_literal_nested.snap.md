----- SOURCE CODE -- main.bp
```botopink
fn make() -> i32 {
    val outer = #(#(1, 2), 3);
    return outer;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

make() ->
    Outer = {{1, 2}, 3},
    Outer.
```

----- RUN LOG -----
```logs
```

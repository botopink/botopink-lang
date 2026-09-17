----- SOURCE CODE -- main.bp
```botopink
fn make() -> #(i32, i32) {
    val r = #(7, 11);
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

make() ->
    R = {7, 11},
    R.
```

----- RUN LOG -----
```logs
```

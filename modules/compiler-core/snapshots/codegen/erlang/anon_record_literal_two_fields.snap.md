----- SOURCE CODE -- main.bp
```botopink
fn make() -> #(i32, i32) {
    val r = #(7, 11);
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__make'/0]).

make() ->
    R = {7, 11},
    R.

'__bp_priv__make'() -> make().
```

----- RUN LOG -----
```logs
```

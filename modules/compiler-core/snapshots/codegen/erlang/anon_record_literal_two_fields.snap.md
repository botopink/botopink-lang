----- SOURCE CODE -- main.bp
```botopink
fn make() -> i32 {
    val r = record { a: 7, b: 11 };
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

make() ->
    R = #{a => 7, b => 11},
    R.
```

----- RUN LOG -----
```logs
```

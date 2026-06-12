----- SOURCE CODE -- main.bp
```botopink
fn make() -> i32 {
    val outer = record { span: record { start: 1, end: 2 }, kind: 3 };
    return outer;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

make() ->
    Outer = #{span => #{start => 1, end => 2}, kind => 3},
    Outer.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
fn n() -> i32 {
    val s = "hello";
    return s.len;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

n() ->
    S = <<"hello">>,
    string:length(S).
```

----- RUN LOG -----
```logs
```

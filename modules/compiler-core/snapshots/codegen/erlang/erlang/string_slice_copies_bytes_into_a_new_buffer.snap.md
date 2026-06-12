----- SOURCE CODE -- main.bp
```botopink
fn first3() -> string {
    val s = "hello";
    return s.slice(0, 3);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% interface String

first3() ->
    S = <<"hello">>,
    slice(S, 0, 3).
```

----- RUN LOG -----
```logs
```

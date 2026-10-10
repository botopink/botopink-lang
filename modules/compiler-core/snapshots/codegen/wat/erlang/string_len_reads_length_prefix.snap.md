----- SOURCE CODE -- main.bp
```botopink
fn n() -> i32 {
    val s = "hello";
    return s.len;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

n() ->
    S = <<"hello">>,
    erlang:length(unicode:characters_to_list(S)).
```

----- RUN LOG -----
```logs
```

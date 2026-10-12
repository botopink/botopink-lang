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
-export(['__bp_priv__n'/0]).

n() ->
    S = <<"hello">>,
    erlang:length(unicode:characters_to_list(S)).

'__bp_priv__n'() -> n().
```

----- RUN LOG -----
```logs
```

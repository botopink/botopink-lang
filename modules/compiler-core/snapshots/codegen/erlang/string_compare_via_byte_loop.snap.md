----- SOURCE CODE -- main.bp
```botopink
fn sameWord() -> bool {
    return "foo" == "bar";
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__sameWord'/0]).

sameWord() ->
    (<<"foo">> =:= <<"bar">>).

'__bp_priv__sameWord'() -> sameWord().
```

----- RUN LOG -----
```logs
```

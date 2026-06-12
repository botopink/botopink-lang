----- SOURCE CODE -- main.bp
```botopink
fn sameWord() -> bool {
    return "foo" == "bar";
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

sameWord() ->
    (<<"foo">> =:= <<"bar">>).
```

----- RUN LOG -----
```logs
```

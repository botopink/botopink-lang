----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val answer = 42;
    val assert 42 = answer catch throw "not 42";
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

f() ->
    Answer = 42,
    case Answer of 42 -> Answer; _ -> erlang:throw(<<"not 42">>) end.
```

----- RUN LOG -----
```logs
```

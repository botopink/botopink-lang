----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn parse() -> @Result<i32, string> {
    return 42;
}
fn f() {
    val result = parse();
    val assert Ok(value) = result catch throw "not ok";
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

parse() ->
    {ok, 42}.

f() ->
    Result = parse(),
    case Result of {ok, Value} -> Result; _ -> erlang:throw(<<"not ok">>) end.
```

----- RUN LOG -----
```logs
```

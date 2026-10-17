----- SOURCE CODE -- main.bp
```botopink
fn fail() {
    throw "something went wrong";
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__fail'/0]).

fail() ->
    erlang:throw(<<"something went wrong">>).

'__bp_priv__fail'() -> fail().
```

----- RUN LOG -----
```logs
```

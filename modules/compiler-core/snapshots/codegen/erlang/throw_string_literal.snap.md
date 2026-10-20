----- SOURCE CODE -- main.bp
```botopink
fn fail() -> Result<void, string> {
    throw "something went wrong";
    return;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__fail'/0]).

fail() ->
    try
        erlang:throw({'__bp_try', {error, <<"something went wrong">>}}),
        {ok, undefined}
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

'__bp_priv__fail'() -> fail().
```

----- RUN LOG -----
```logs
```

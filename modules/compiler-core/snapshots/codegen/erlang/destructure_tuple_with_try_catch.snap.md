----- SOURCE CODE -- main.bp
```botopink
type Error(msg: string)
fn fetch() -> Result<#(i32, i32), Error> {
    throw Error(msg: "boom");
}
fn f() -> Result<void, Error> {
    val #(a, b) = try fetch() catch throw Error(msg: "failed");
    return;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__fetch'/0, '__bp_priv__f'/0]).

%% type Error: msg

fetch() ->
    {error, {test@main@@Error, <<"boom">>}}.

f() ->
    try
        {A, B} = case fetch() of
            {ok, TryV0} -> TryV0;
            {error, _TryE0} ->
                erlang:throw({'__bp_try', {error, {test@main@@Error, <<"failed">>}}})
        end,
        {ok, undefined}
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

'__bp_priv__fetch'() -> fetch().

'__bp_priv__f'() -> f().
```

----- ERLANG -- test@main@@Error.erl
```erlang
-module(test@main@@Error).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, msg) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Error", [{"msg", erlang:element(2, V)}]}.
```

----- RUN LOG -----
```logs
```

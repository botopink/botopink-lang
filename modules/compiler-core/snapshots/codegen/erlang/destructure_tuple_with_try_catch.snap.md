----- SOURCE CODE -- main.bp
```botopink
type Error(msg: string)
fn fetch() -> Result<#(i32, i32), Error> {
    throw Error(msg: "boom");
}
fn f() {
    val #(a, b) = try fetch() catch throw Error(msg: "failed");
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
    {A, B} = case fetch() of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            erlang:throw({test@main@@Error, <<"failed">>})
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

----- SOURCE CODE -- main.bp
```botopink
type Error(msg: string)
fn fetch() -> @Result<#(i32, i32), Error> {
    throw Error(msg: "boom");
}
fn f() {
    val #(a, b) = try fetch() catch throw Error(msg: "failed");
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Error: msg

fetch() ->
    {error, {test@main@@Error, <<"boom">>}}.

f() ->
    {A, B} = case try
        fetch()
    catch
        error:_TryR0 -> {error, _TryR0}
    end of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            erlang:throw({test@main@@Error, <<"failed">>})
    end.
```

----- ERLANG -- test@main@@Error.erl
```erlang
-module(test@main@@Error).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, msg) -> element(2, V).

'__bp_format'(V) -> {record, "Error", [{"msg", element(2, V)}]}.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
val ErrorKind = type { NotFound, Timeout }
fn fetch() -> Result<i32, ErrorKind> {
    throw ErrorKind.NotFound;
}
fn handle() -> i32 {
    val r = try fetch() catch 0;
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__fetch'/0, '__bp_priv__handle'/0]).

%% type ErrorKind
%%   NotFound
%%   Timeout

fetch() ->
    {error, test@main@@ErrorKind__v__notfound}.

handle() ->
    R = case fetch() of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            0
    end,
    R.

'__bp_priv__fetch'() -> fetch().

'__bp_priv__handle'() -> handle().
```

----- ERLANG -- test@main@@ErrorKind.erl
```erlang
-module(test@main@@ErrorKind).
-export(['__bp_format'/1]).

'__bp_format'(test@main@@ErrorKind__v__notfound) -> {variant, "ErrorKind.NotFound", []};
'__bp_format'(test@main@@ErrorKind__v__timeout) -> {variant, "ErrorKind.Timeout", []}.
```

----- RUN LOG -----
```logs
```

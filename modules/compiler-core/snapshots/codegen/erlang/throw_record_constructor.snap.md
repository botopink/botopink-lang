----- SOURCE CODE -- main.bp
```botopink
type AppError(code: i32, msg: string)
fn validate(x: i32) -> Result<void, AppError> {
    if (x < 0) {
        throw AppError(code: 400, msg: "negative");
    };
    return;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__validate'/1]).

%% type AppError: code, msg

validate(X) ->
    case (X < 0) of
        true ->
            {error, {test@main@@AppError, 400, <<"negative">>}};
        _ ->
            {ok, undefined}
    end.

'__bp_priv__validate'(A0) -> validate(A0).
```

----- ERLANG -- test@main@@AppError.erl
```erlang
-module(test@main@@AppError).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, code) -> erlang:element(2, V);
'__bp_get'(V, msg) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "AppError", [{"code", erlang:element(2, V)}, {"msg", erlang:element(3, V)}]}.
```

----- RUN LOG -----
```logs
```

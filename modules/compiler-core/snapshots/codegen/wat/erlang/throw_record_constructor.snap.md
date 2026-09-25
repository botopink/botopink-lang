----- SOURCE CODE -- main.bp
```botopink
type AppError(code: i32, msg: string)
fn validate(x: i32) {
    if (x < 0) {
        throw AppError(code: 400, msg: "negative");
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type AppError: code, msg

validate(X) ->
    case (X < 0) of
        true ->
            erlang:throw({test@main@@AppError, 400, <<"negative">>});
        _ -> ok
    end.
```

----- ERLANG -- test@main@@AppError.erl
```erlang
-module(test@main@@AppError).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, code) -> element(2, V);
'__bp_get'(V, msg) -> element(3, V).

'__bp_format'(V) -> {record, "AppError", [{"code", element(2, V)}, {"msg", element(3, V)}]}.
```

----- RUN LOG -----
```logs
```

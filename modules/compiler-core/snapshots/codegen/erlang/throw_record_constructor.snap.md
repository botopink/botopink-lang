----- SOURCE CODE -- main.bp
```botopink
record AppError { code: i32, msg: string }
fn validate(x: i32) {
    if (x < 0) {
        throw AppError(code: 400, msg: "negative");
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record AppError: code, msg

validate(X) ->
    case (X < 0) of
        true ->
            erlang:throw(#{code => 400, msg => <<"negative">>});
        _ -> ok
    end.
```

----- RUN LOG -----
```logs
```

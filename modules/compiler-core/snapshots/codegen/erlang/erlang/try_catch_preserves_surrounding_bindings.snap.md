----- SOURCE CODE -- main.bp
```botopink
record LoadError { msg: string }
*fn load() -> @Result<i32, LoadError> {
    throw LoadError(msg: "not found");
}
fn process() -> i32 {
    val prefix = 10;
    val data = try load() catch 0;
    val suffix = 20;
    @print(prefix, data, suffix);
    return prefix + data + suffix;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record LoadError: msg

load() ->
    {error, #{msg => <<"not found">>}}.

process() ->
    Prefix = 10,
    Data = case load() of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            0
    end,
    Suffix = 20,
    io:format("~p~n", [Prefix, Data, Suffix]),
    ((Prefix + Data) + Suffix).
```

----- RUN LOG -----
```logs
```

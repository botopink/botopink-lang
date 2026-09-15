----- SOURCE CODE -- main.bp
```botopink
record LoadError { msg: string }
#[@result]
fn load() -> @Result<i32, LoadError> {
    throw LoadError(msg: "not found");
}
fn process() -> i32 {
    val prefix = 10;
    val data = try load() catch 0;
    val suffix = 20;
    @print(prefix, data, suffix);
    return prefix + data + suffix;
}
fn main() {
    @print(process());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

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

main() ->
    io:format("~p~n", [process()]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

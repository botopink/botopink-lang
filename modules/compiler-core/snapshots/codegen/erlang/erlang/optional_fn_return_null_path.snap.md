----- SOURCE CODE -- main.bp
```botopink
record R { kind: i32 }
fn pick(present: bool) -> ?R {
    if (present) {
        return R(kind: 7);
    } else {
        return null;
    }
}
fn main() {
    @print(pick(false)?.kind);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% record R: kind

pick(Present) ->
    case Present of
        true ->
            #{kind => 7};
        false ->
            undefined
    end.

main() ->
    io:format("~p~n", [(fun(undefined) -> undefined; (_Opt0) -> maps:get(kind, _Opt0) end)(pick(false))]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
undefined
```

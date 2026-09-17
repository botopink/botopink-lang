----- SOURCE CODE -- main.bp
```botopink
record R { kind: i32 }
fn choose(present: bool) -> ?R {
    if (present) {
        return R(kind: 7);
    } else {
        return null;
    }
}
fn main() {
    @print(choose(true)?.kind);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% record R: kind

choose(Present) ->
    case Present of
        true ->
            #{kind => 7};
        false ->
            undefined
    end.

main() ->
    '__bp_print'([(fun(undefined) -> undefined; (_Opt0) -> maps:get(kind, _Opt0) end)(choose(true))]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
7
```

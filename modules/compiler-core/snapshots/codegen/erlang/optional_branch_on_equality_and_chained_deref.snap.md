----- SOURCE CODE -- main.bp
```botopink
record R { kind: i32 }
fn main() {
    val r = R(kind: 11);
    val maybe: ?R = r;
    if (maybe == null) {
        @print(0);
    } else {
        @print(maybe?.kind);
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% record R: kind

main() ->
    R = #{kind => 11},
    Maybe = R,
    case (Maybe =:= undefined) of
        true ->
            '__bp_print'([0]);
        false ->
            '__bp_print'([(fun(undefined) -> undefined; (_Opt0) -> maps:get(kind, _Opt0) end)(Maybe)])
    end.

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
11
```

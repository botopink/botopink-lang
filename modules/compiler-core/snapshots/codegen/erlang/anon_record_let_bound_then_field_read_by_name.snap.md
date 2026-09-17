----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val r = record { code: 7, kind: 11 };
    @print(r.kind);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    R = #{code => 7, kind => 11},
    '__bp_print'([maps:get(kind, R)]).

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

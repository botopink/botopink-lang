----- SOURCE CODE -- main.bp
```botopink
fn main() {
    @print(true.negate());
    @print(false.nor(false));
    @print(true.nand(true));
    @print(true.exclusiveOr(false));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% interface Bool

main() ->
    '__bp_print'([(not true)]),
    '__bp_print'([bool_nor(false, false)]),
    '__bp_print'([bool_nand(true, true)]),
    '__bp_print'([bool_exclusiveOr(true, false)]).

bool_nor(Self, Other) ->
    (not ((Self orelse Other))).

bool_nand(Self, Other) ->
    (not ((Self andalso Other))).

bool_exclusiveOr(Self, Other) ->
    (Self =/= Other).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
false
true
false
true
```

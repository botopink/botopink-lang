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
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(",", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> io_lib:format("~p", [V]);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(",", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

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

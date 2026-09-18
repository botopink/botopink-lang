----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val xs = [10, 20, 30];
    val i = 1;
    @print(xs[0]);
    @print(xs[i + 1]);
    val names = ["ana", "bo"];
    @print(names[1]);
    val s = "hello";
    @print(s[1]);
    @print(s[1..3]);
    @print(s[3..]);
    @print(xs[1..]);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    Xs = [10, 20, 30],
    I = 1,
    '__bp_print'(['[]'(Xs, 0)]),
    '__bp_print'(['[]'(Xs, (I + 1))]),
    Names = [<<"ana">>, <<"bo">>],
    '__bp_print'(['[]'(Names, 1)]),
    S = <<"hello">>,
    '__bp_print'(['[]'(S, 1)]),
    '__bp_print'(['[]'(S, lists:seq(1, (3) - 1))]),
    '__bp_print'(['[]'(S, lists:seq(3, infinity))]),
    '__bp_print'(['[]'(Xs, lists:seq(1, infinity))]).

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
COMPILE ERROR (erlc):
main.erl:7:19: function '[]'/2 undefined
main.erl:8:19: function '[]'/2 undefined
main.erl:10:19: function '[]'/2 undefined
main.erl:12:19: function '[]'/2 undefined
main.erl:13:19: function '[]'/2 undefined
main.erl:14:19: function '[]'/2 undefined
main.erl:15:19: function '[]'/2 undefined
```

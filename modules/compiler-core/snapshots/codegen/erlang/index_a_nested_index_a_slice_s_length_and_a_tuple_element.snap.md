----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val rows = [[1, 2], [3, 4]];
    @print(rows);
    @print(rows[1]);
    @print(rows[1][0]);
    @print(rows[0].length);
    val xs = [10, 20, 30];
    @print(xs[0..2].length);
    val sl = xs[0..2];
    @print(sl.length);
    val ps = [#(1, "a"), #(2, "b")];
    @print(ps[1]);
    val s = "hello";
    @print(s[1..3].length);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    Rows = [[1, 2], [3, 4]],
    '__bp_print'([Rows]),
    '__bp_print'(['[]'(Rows, 1)]),
    '__bp_print'(['[]'('[]'(Rows, 1), 0)]),
    '__bp_print'(['__bp_len'('[]'(Rows, 0), length)]),
    Xs = [10, 20, 30],
    '__bp_print'(['__bp_len'('[]'(Xs, lists:seq(0, (2) - 1)), length)]),
    Sl = '[]'(Xs, lists:seq(0, (2) - 1)),
    '__bp_print'(['__bp_len'(Sl, length)]),
    Ps = [{1, <<"a">>}, {2, <<"b">>}],
    '__bp_print'(['[]'(Ps, 1)]),
    S = <<"hello">>,
    '__bp_print'(['__bp_len'('[]'(S, lists:seq(1, (3) - 1)), length)]).

'__bp_len'(X, _) when is_list(X) -> length(X);
'__bp_len'(X, _) when is_binary(X) -> string:length(X);
'__bp_len'(X, Field) -> maps:get(Field, X).

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
main.erl:8:24: function '[]'/2 undefined
main.erl:9:30: function '[]'/2 undefined
main.erl:11:30: function '[]'/2 undefined
main.erl:12:10: function '[]'/2 undefined
main.erl:15:19: function '[]'/2 undefined
main.erl:17:30: function '[]'/2 undefined
```

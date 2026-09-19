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
    '__bp_print'(['__bp_index'(Rows, 1)]),
    '__bp_print'(['__bp_index'('__bp_index'(Rows, 1), 0)]),
    '__bp_print'(['__bp_len'('__bp_index'(Rows, 0), length)]),
    Xs = [10, 20, 30],
    '__bp_print'(['__bp_len'('__bp_slice'(Xs, 0, 2), length)]),
    Sl = '__bp_slice'(Xs, 0, 2),
    '__bp_print'(['__bp_len'(Sl, length)]),
    Ps = [{1, <<"a">>}, {2, <<"b">>}],
    '__bp_print'(['__bp_index'(Ps, 1)]),
    S = <<"hello">>,
    '__bp_print'(['__bp_len'('__bp_slice'(S, 1, 3), length)]).

'__bp_len'(X, _) when is_list(X) -> length(X);
'__bp_len'(X, _) when is_binary(X) -> string:length(X);
'__bp_len'(X, Field) -> maps:get(Field, X).

'__bp_index'(Recv, I) when is_list(Recv), is_integer(I), I >= 0, I < length(Recv) -> lists:nth(I + 1, Recv);
'__bp_index'(Recv, I) when is_binary(Recv), is_integer(I), I >= 0 -> string:slice(Recv, I, 1);
'__bp_index'(Recv, I) when is_tuple(Recv), is_integer(I), I >= 0, I < tuple_size(Recv) -> element(I + 1, Recv);
'__bp_index'(Recv, I) when is_list(Recv), is_integer(I) -> undefined;
'__bp_index'(Recv, I) when is_tuple(Recv), is_integer(I) -> undefined;
'__bp_index'(Recv, I) -> erlang:error({bp_unsupported_index, Recv, I}).

'__bp_slice'(Recv, From, infinity) when is_list(Recv) -> lists:nthtail(min(max(From, 0), length(Recv)), Recv);
'__bp_slice'(Recv, From, infinity) when is_binary(Recv) -> string:slice(Recv, max(From, 0));
'__bp_slice'(Recv, From, To) when is_list(Recv) -> lists:sublist(Recv, max(From, 0) + 1, max(To - max(From, 0), 0));
'__bp_slice'(Recv, From, To) when is_binary(Recv) -> string:slice(Recv, max(From, 0), max(To - max(From, 0), 0));
'__bp_slice'(Recv, From, To) -> erlang:error({bp_unsupported_slice, Recv, From, To}).

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
[[1,2],[3,4]]
[3,4]
3
2
2
2
#(2,"b")
2
```

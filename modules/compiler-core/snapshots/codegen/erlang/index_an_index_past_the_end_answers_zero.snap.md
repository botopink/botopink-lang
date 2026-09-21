----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val xs = [10, 20, 30];
    @print(xs[9]);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    Xs = [10, 20, 30],
    '__bp_print'(['__bp_index'(Xs, 9)]).

'__bp_index'(Recv, I) when is_list(Recv), is_integer(I), I >= 0, I < length(Recv) -> lists:nth(I + 1, Recv);
'__bp_index'(Recv, I) when is_binary(Recv), is_integer(I), I >= 0 -> string:slice(Recv, I, 1);
'__bp_index'(Recv, I) when is_tuple(Recv), is_integer(I), I >= 0, I < tuple_size(Recv) -> element(I + 1, Recv);
'__bp_index'(Recv, I) when is_list(Recv), is_integer(I) -> undefined;
'__bp_index'(Recv, I) when is_tuple(Recv), is_integer(I) -> undefined;
'__bp_index'(Recv, I) -> erlang:error({bp_unsupported_index, Recv, I}).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> '__bp_tagged'(element(1, V), V);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) when is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(atom_to_list(A), "__v__") of [P, _] -> list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
undefined
```

----- SOURCE CODE -- main.bp
```botopink
type P(x: i32, y: i32)
fn main() {
    val pts = [P(x: 1, y: 2), P(x: 3, y: 4)];
    @print(pts.len);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

%% type P: x, y

main() ->
    Pts = [{test@main@@P, 1, 2}, {test@main@@P, 3, 4}],
    '__bp_print'([length(Pts)]).

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

----- ERLANG -- test@main@@P.erl
```erlang
-module(test@main@@P).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, x) -> element(2, V);
'__bp_get'(V, y) -> element(3, V).

'__bp_format'(V) -> {record, "P", [{"x", element(2, V)}, {"y", element(3, V)}]}.
```

----- RUN LOG -----
```logs
2
```

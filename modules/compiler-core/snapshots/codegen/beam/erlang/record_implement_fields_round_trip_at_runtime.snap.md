----- SOURCE CODE -- main.bp
```botopink
val E = type(tag: string, n: i32) implement @Context<E, E>
fn mk() -> E {
    return E(tag: "x", n: 5);
}
fn main() {
    @print(mk().n);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

%% type E: tag, n

mk() ->
    {test@main@@E, <<"x">>, 5}.

main() ->
    '__bp_print'([element(3, mk())]).

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

----- ERLANG -- test@main@@E.erl
```erlang
-module(test@main@@E).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, tag) -> element(2, V);
'__bp_get'(V, n) -> element(3, V).

'__bp_format'(V) -> {record, "E", [{"tag", element(2, V)}, {"n", element(3, V)}]}.
```

----- RUN LOG -----
```logs
5
```

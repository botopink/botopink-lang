----- SOURCE CODE -- main.bp
```botopink
fn locate() -> SourceLocation {
    return @src();
}
fn main() {
    val loc = locate();
    @print(loc.file, loc.line, loc.column, loc.fnName);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

%% type SourceLocation: file, line, column, fnName

locate() ->
    {test@main@@SourceLocation, <<"main.bp">>, 2, 12, <<"locate">>}.

main() ->
    Loc = locate(),
    '__bp_print'([element(2, Loc), element(3, Loc), element(4, Loc), element(5, Loc)]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> '__bp_tagged'(element(1, V), V);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
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

----- ERLANG -- test@main@@SourceLocation.erl
```erlang
-module(test@main@@SourceLocation).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, file) -> element(2, V);
'__bp_get'(V, line) -> element(3, V);
'__bp_get'(V, column) -> element(4, V);
'__bp_get'(V, fnName) -> element(5, V).

'__bp_format'(V) -> {record, "SourceLocation", [{"file", element(2, V)}, {"line", element(3, V)}, {"column", element(4, V)}, {"fnName", element(5, V)}]}.
```

----- RUN LOG -----
```logs
main.bp 2 12 locate
```

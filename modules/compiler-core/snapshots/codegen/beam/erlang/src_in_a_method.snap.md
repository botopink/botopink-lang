----- SOURCE CODE -- main.bp
```botopink
type Stub(n: i32) {
    fn where(self: Self) -> SourceLocation {
        return @src();
    }
}
fn main() {
    val loc = Stub(n: 1).where();
    @print(loc.file, loc.line, loc.column, loc.fnName);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

%% type SourceLocation: file, line, column, fnName

%% type Stub: n

main() ->
    Loc = test@main@@Stub:where({test@main@@Stub, 1}),
    '__bp_print'([erlang:element(2, Loc), erlang:element(3, Loc), erlang:element(4, Loc), erlang:element(5, Loc)]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when erlang:is_tuple(V), erlang:tuple_size(V) > 0, erlang:is_atom(erlang:element(1, V)), erlang:element(1, V) =/= true, erlang:element(1, V) =/= false, erlang:element(1, V) =/= undefined -> '__bp_tagged'(erlang:element(1, V), V);
'__bp_show'(V, _) when erlang:is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- erlang:tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when erlang:is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(erlang:atom_to_list(A), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(erlang:apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

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

'__bp_get'(V, file) -> erlang:element(2, V);
'__bp_get'(V, line) -> erlang:element(3, V);
'__bp_get'(V, column) -> erlang:element(4, V);
'__bp_get'(V, fnName) -> erlang:element(5, V).

'__bp_format'(V) -> {record, "SourceLocation", [{"file", erlang:element(2, V)}, {"line", erlang:element(3, V)}, {"column", erlang:element(4, V)}, {"fnName", erlang:element(5, V)}]}.
```

----- ERLANG -- test@main@@Stub.erl
```erlang
-module(test@main@@Stub).
-export([where/1, '__bp_get'/2, '__bp_format'/1]).

where(Self) ->
    {test@main@@SourceLocation, <<"main.bp">>, 3, 16, <<"Stub.where">>}.

'__bp_get'(V, n) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Stub", [{"n", erlang:element(2, V)}]}.
```

----- RUN LOG -----
```logs
main.bp 3 16 Stub.where
```

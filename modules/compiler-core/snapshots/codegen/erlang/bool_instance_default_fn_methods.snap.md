----- SOURCE CODE -- main.bp
```botopink
fn main() -> void {
    print(true.negate());
    print(false.nor(false));
    print(true.nand(true));
    print(true.exclusiveOr(false));
}

import {io.terminal.print} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export(['__bp_priv__main'/0, '__bp_priv__bool_nor'/2, '__bp_priv__bool_nand'/2, '__bp_priv__bool_exclusiveOr'/2]).

%% behavior bool

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

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'({ok, P}, _) -> ["Ok(", '__bp_show'(P, false), $)];
'__bp_show'({error, P}, _) -> ["Error(", '__bp_show'(P, false), $)];
'__bp_show'(V, _) when erlang:is_tuple(V), erlang:tuple_size(V) > 0, erlang:is_atom(erlang:element(1, V)), erlang:element(1, V) =/= true, erlang:element(1, V) =/= false, erlang:element(1, V) =/= undefined -> '__bp_tagged'(erlang:element(1, V), V);
'__bp_show'(V, _) when erlang:is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- erlang:tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when erlang:is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) when erlang:is_function(V) -> ["fn/", erlang:integer_to_list(erlang:element(2, erlang:fun_info(V, arity)))];
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(erlang:atom_to_list(A), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(erlang:apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__main'() -> main().

'__bp_priv__bool_nor'(A0, A1) -> bool_nor(A0, A1).

'__bp_priv__bool_nand'(A0, A1) -> bool_nand(A0, A1).

'__bp_priv__bool_exclusiveOr'(A0, A1) -> bool_exclusiveOr(A0, A1).
```

----- RUN LOG -----
```logs
false
true
false
true
```

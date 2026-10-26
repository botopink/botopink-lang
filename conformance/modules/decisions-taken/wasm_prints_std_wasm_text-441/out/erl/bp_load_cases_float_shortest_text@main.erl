-module(bp_load_cases_float_shortest_text@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__id'/1]).

%%% A float prints, and turns into text, as the shortest decimal that reads

%%% back as the same `f64` — the text commonJS writes for it (`Number#toString`),

%%% and erlang and beam (`float_to_list(F, [short])`) for every value below.

%%% 

%%% The wasm gap this pins (`00 · gate-wasm-wrong-answers`): its formatter wrote

%%% an integer part and at most six fraction digits, so `0.1 + 0.2` printed

%%% `0.3`, `1.0 / 3.0` printed `0.333333` and `0.26642920868471265` printed

%%% `0.266429` — each at exit 0 — and a float past `2^31` trapped. It is now

%%% std-wasm's text (decisions 440, 441: `float_to_binary(F, [short])`, the

%%% erlang target's), which every value below shares with commonJS; the forms

%%% where the two differ (`5.0`, `1.0e21`) are pinned in `codegen/tests/wat.zig`.

id(X) ->
    X.

main() ->
    '__bp_print'([(0.1 + 0.2)]),
    '__bp_print'([(1.0 / 3.0)]),
    '__bp_print'([(id(2.0) / 3.0)]),
    '__bp_print'([0.26642920868471265]),
    '__bp_print'([123456789012.5]),
    '__bp_print'([4294967296.5]),
    '__bp_print'([100.0]),
    '__bp_print'([id((-2.5))]),
    '__bp_print'([(id(0.1) * 3.0)]),
    '__bp_print'([float_to_binary(((0.1 + 0.2)), [short])]),
    '__bp_print'([<<"x", ('__bp_text'(2.5))/binary>>]),
    '__bp_print'([<<"x", ('__bp_text'(((1.0 / 3.0))))/binary>>]),
    '__bp_print'([[0.1, (1.0 / 3.0)]]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/float_shortest_text|*">>.

'__bp_text'(Value) when erlang:is_binary(Value) -> Value;
'__bp_text'(Value) -> unicode:characters_to_binary('__bp_show'(Value, true)).

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

'__bp_priv__id'(A0) -> id(A0).

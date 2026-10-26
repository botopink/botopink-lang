-module(bp_load_cases_f64_equality_total_order@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__zero'/0]).

%%% Decision 214 — `==` over `f64` is a total order, as Java's

%%% `Double.compare` and Kotlin's data class: `0.0 == -0.0` is `false`, for a

%%% bare `f64` and for one inside a record, a tuple, an array or a variant

%%% alike; `<`, `>`, `<=`, `>=` keep IEEE ordering (`-0.0 < 0.0` is `false`).

%%% erlang and beam already separate the zeros (`=:=`); commonJS (`===`) and

%%% wasm (`f64.eq`) answered `true`. `-0.0` is built at run time, as

%%% `zero() * -1.0`, so no backend folds it.

%%% 

%%% The NaN half (`NaN == NaN` is `true`) is not in this cell: erlang and beam

%%% never produce a NaN (`z / z` raises `badarith`), and the runner narrows a

%%% cell only on a host binding a target lacks, which a division is not. Each

%%% backend that has NaN pins it in its own RUN LOG fixture

%%% (`codegen/tests/commonjs.zig`, `codegen/tests/wat.zig`).

%% type F: x

%% type V
%%   W(x)
%%   Z

zero() ->
    0.0.

main() ->
    Z = zero(),
    Neg = (Z * (-1.0)),
    '__bp_print'([(Z =:= Neg)]),
    '__bp_print'([(Z =/= Neg)]),
    '__bp_print'([(Z =:= zero())]),
    '__bp_print'([(Neg =:= Neg)]),
    '__bp_print'([(Neg < Z)]),
    '__bp_print'([(Neg =< Z)]),
    '__bp_print'([(Neg >= Z)]),
    '__bp_print'([({bp_load_cases_f64_equality_total_order@main@@F, Z} =:= {bp_load_cases_f64_equality_total_order@main@@F, Neg})]),
    '__bp_print'([({bp_load_cases_f64_equality_total_order@main@@F, Z} =/= {bp_load_cases_f64_equality_total_order@main@@F, Neg})]),
    '__bp_print'([({bp_load_cases_f64_equality_total_order@main@@F, Z} =:= {bp_load_cases_f64_equality_total_order@main@@F, zero()})]),
    Ta = {Z, 1},
    Tb = {Neg, 1},
    Tc = {zero(), 1},
    '__bp_print'([(Ta =:= Tb)]),
    '__bp_print'([(Ta =:= Tc)]),
    Xs = [Z, 1.5],
    Ys = [Neg, 1.5],
    Zs = [zero(), 1.5],
    '__bp_print'([(Xs =:= Ys)]),
    '__bp_print'([(Xs =:= Zs)]),
    '__bp_print'([({bp_load_cases_f64_equality_total_order@main@@V__v__w, Z} =:= {bp_load_cases_f64_equality_total_order@main@@V__v__w, Neg})]),
    '__bp_print'([({bp_load_cases_f64_equality_total_order@main@@V__v__w, Z} =:= {bp_load_cases_f64_equality_total_order@main@@V__v__w, zero()})]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/f64_equality_total_order|*">>.

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

'__bp_priv__zero'() -> zero().

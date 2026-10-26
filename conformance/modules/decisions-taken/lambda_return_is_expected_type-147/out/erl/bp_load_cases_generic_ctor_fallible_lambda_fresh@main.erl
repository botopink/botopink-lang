-module(bp_load_cases_generic_ctor_fallible_lambda_fresh@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, optionalOf/2, arrayOf/2, '__bp_priv__present'/1, '__bp_priv__shout'/1]).

%%% Decision 147 (lg-a) beside a generic constructor: a lambda argument of a

%%% fallible field takes the expectation of a FRESH instance of the

%%% constructor, so `Box(…)` answering `Box<?T>` in one method leaves the next

%%% `Box(…)`, answering `Box<Array<T>>`, free.

%% type Box: run

present(V) ->
    (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)([V], 0).

optionalOf(At, Inner) ->
    case Inner(At) of
        {ok, V} ->
            {ok, present(V)};
        {error, _TryE0} -> {error, _TryE0}
    end.

arrayOf(At, Inner) ->
    case Inner(At) of
        {ok, V} ->
            {ok, [V, V]};
        {error, _TryE0} -> {error, _TryE0}
    end.

shout(At) ->
    case (At =:= <<"">>) of
        true ->
            {error, <<"empty">>};
        _ ->
            {ok, <<At/binary, "!">>}
    end.

main() ->
    Box = {bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box, fun shout/1},
    Many = erlang:element(2, bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box:array(Box)),
    '__bp_print'([erlang:length((fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> ([]) end end)(Many(<<"hi">>)))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {error, _} -> true; _ -> false end end)(Many(<<"">>))]),
    Maybe = erlang:element(2, bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box:optional(Box)),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, _} -> true; _ -> false end end)(Maybe(<<"yo">>))]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/generic_ctor_fallible_lambda_fresh|*">>.

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

'__bp_priv__present'(A0) -> present(A0).

'__bp_priv__shout'(A0) -> shout(A0).

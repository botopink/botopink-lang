-module(bp_load_cases_defer_reads_binding_at_defer@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__name'/0, '__bp_priv__work'/0, '__bp_priv__viaBranch'/1]).

%%% Decision 539 (amended) — names bind where `defer` is written, only the

%%% value is read late: a `val` written after the `defer` that shadows a

%%% name the deferred code reads is another binding, and the deferred code

%%% does not see it.

name() ->
    <<"global">>.

work() ->
    try
        Name = <<"local">>,
        '__bp_print'([<<"work ", Name/binary>>])
    after
        '__bp_print'([<<"close ", (name())/binary>>])
    end.

viaBranch(C) ->
    try
        try
            case C of
                true ->
                    Name = <<"branch">>,
                    '__bp_print'([<<"in ", Name/binary>>]),
                    erlang:throw({'__bp_try', undefined});
                _ -> ok
            end,
            '__bp_print'([<<"after">>])
        after
            '__bp_print'([<<"close ", (name())/binary>>])
        end
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

main() ->
    work(),
    viaBranch(true),
    viaBranch(false).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/defer_reads_binding_at_defer|*">>.

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

'__bp_priv__name'() -> name().

'__bp_priv__work'() -> work().

'__bp_priv__viaBranch'(A0) -> viaBranch(A0).

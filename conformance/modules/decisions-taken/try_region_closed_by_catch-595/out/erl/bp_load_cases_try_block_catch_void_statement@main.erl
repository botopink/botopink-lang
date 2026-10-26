-module(bp_load_cases_try_block_catch_void_statement@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__save'/1, '__bp_priv__saveBoth'/2]).

%%% Decision 595 (4) — a region whose value is `void` is a statement; its

%%% handler is a block with at least one statement. The first failing `try`

%%% ends the region: the second `save` does not run.

save(N) ->
    case (N < 0) of
        true ->
            {error, <<"negative">>};
        _ ->
            '__bp_print'([<<"saved ", ('__bp_text'(erlang:integer_to_binary(N)))/binary>>]),
            {ok, undefined}
    end.

saveBoth(A, B) ->
    try
        case true of
            _ ->
                case save(A) of
                    {ok, _TryV1} -> _TryV1;
                    {error, _TryE1} -> erlang:throw({'__bp_region', _TryE1})
                end,
                case save(B) of
                    {ok, _TryV2} -> _TryV2;
                    {error, _TryE2} -> erlang:throw({'__bp_region', _TryE2})
                end
        end
    catch
        throw:{'__bp_region', _RgE0} -> case true of
            _ ->
                '__bp_print'([<<"not saved">>])
        end
    end,
    '__bp_print'([<<"done">>]).

main() ->
    saveBoth(1, 2),
    saveBoth((-1), 2).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/try_block_catch_void_statement|*">>.

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

'__bp_priv__save'(A0) -> save(A0).

'__bp_priv__saveBoth'(A0, A1) -> saveBoth(A0, A1).

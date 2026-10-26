-module(bp_load_cases_try_block_catch_value@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__half'/1, '__bp_priv__quarter'/1, '__bp_priv__halves'/2]).

%%% Decision 595 (2), (3), (4) — `try { … } catch …` is a region: every `try`

%%% written in the block hands its failure to the one `catch`, so a function

%%% with no `Result` in its return runs fallible calls. The block's value is its

%%% last expression written without `;`; the handler is the fallback — an

%%% expression, or a block whose value is its last expression.

half(N) ->
    case ((N rem 2) =/= 0) of
        true ->
            {error, <<"odd">>};
        _ ->
            {ok, '__bp_int'((N div 2), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/main.bp:11:14">>)}
    end.

quarter(N) ->
    try
        case true of
            _ ->
                H = case half(N) of
                    {ok, _TryV1} -> _TryV1;
                    {error, _TryE1} -> erlang:throw({'__bp_region', _TryE1})
                end,
                case half(H) of
                    {ok, _TryV2} -> _TryV2;
                    {error, _TryE2} -> erlang:throw({'__bp_region', _TryE2})
                end
        end
    catch
        throw:{'__bp_region', _RgE0} -> 0
    end.

halves(A, B) ->
    Total = try
        case true of
            _ ->
                '__bp_add'(case half(A) of
                    {ok, _TryV1} -> _TryV1;
                    {error, _TryE1} -> erlang:throw({'__bp_region', _TryE1})
                end, case half(B) of
                    {ok, _TryV2} -> _TryV2;
                    {error, _TryE2} -> erlang:throw({'__bp_region', _TryE2})
                end)
        end
    catch
        throw:{'__bp_region', _RgE0} -> case true of
            _ ->
                '__bp_print'([<<"not even">>]),
                (-1)
        end
    end,
    Total.

main() ->
    '__bp_print'([quarter(8)]),
    '__bp_print'([quarter(6)]),
    '__bp_print'([halves(4, 6)]),
    '__bp_print'([halves(4, 5)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/try_block_catch_value|*">>.

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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

'__bp_priv__half'(A0) -> half(A0).

'__bp_priv__quarter'(A0) -> quarter(A0).

'__bp_priv__halves'(A0, A1) -> halves(A0, A1).

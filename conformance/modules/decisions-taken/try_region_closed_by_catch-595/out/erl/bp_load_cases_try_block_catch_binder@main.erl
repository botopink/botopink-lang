-module(bp_load_cases_try_block_catch_binder@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__half'/1, '__bp_priv__describe'/1]).

%%% Decision 595 (3) — `catch { e -> … }`: `e` is the region's error, a `case`

%%% arm's binder typed by the region (656), matched with `case`. The block's

%%% value is the fallback.

%% type HalfError
%%   Odd(value)
%%   Negative

half(N) ->
    case (N < 0) of
        true ->
            {error, bp_load_cases_try_block_catch_binder@main@@HalfError__v__negative};
        _ ->
            case ((N rem 2) =/= 0) of
                true ->
                    {error, {bp_load_cases_try_block_catch_binder@main@@HalfError__v__odd, N}};
                _ ->
                    {ok, '__bp_int'((N div 2), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/main.bp:12:14">>)}
            end
    end.

describe(N) ->
    try
        case true of
            _ ->
                H = case half(N) of
                    {ok, _TryV1} -> _TryV1;
                    {error, _TryE1} -> erlang:throw({'__bp_region', _TryE1})
                end,
                Q = case half(H) of
                    {ok, _TryV2} -> _TryV2;
                    {error, _TryE2} -> erlang:throw({'__bp_region', _TryE2})
                end,
                <<"quarter ", ('__bp_text'(erlang:integer_to_binary(Q)))/binary>>
        end
    catch
        throw:{'__bp_region', E} -> case true of
            _ ->
                case E of
                    {bp_load_cases_try_block_catch_binder@main@@HalfError__v__odd, Value} ->
                        <<"odd ", ('__bp_text'(erlang:integer_to_binary(Value)))/binary>>;
                    bp_load_cases_try_block_catch_binder@main@@HalfError__v__negative ->
                        <<"negative">>
                end
        end
    end.

main() ->
    '__bp_print'([describe(12)]),
    '__bp_print'([describe(6)]),
    '__bp_print'([describe((-4))]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/try_block_catch_binder|*">>.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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

'__bp_priv__half'(A0) -> half(A0).

'__bp_priv__describe'(A0) -> describe(A0).

-module(bp_load_cases_try_block_catch_rethrow@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__lookup'/1, '__bp_priv__sum'/2, '__bp_priv__port'/1, '__bp_priv__show'/1]).

%%% Decision 595 (3), (5) — the handler converts the region's failure into the

%%% function's: `catch throw …`, or a block with a binder whose `throw` is the

%%% enclosing function's (the block is no lambda). Each region fails with one

%%% error type (`string` here); the function answers its own (`ConfigError`).

%% type ConfigError
%%   Missing(key)
%%   Invalid

lookup(Key) ->
    case (Key =:= <<"port">>) of
        true ->
            {ok, 80};
        _ ->
            case (Key =:= <<"offset">>) of
                true ->
                    {ok, 1};
                _ ->
                    {error, Key}
            end
    end.

sum(A, B) ->
    try
        {ok, try
            case true of
                _ ->
                    '__bp_add'(case lookup(A) of
                        {ok, _TryV1} -> _TryV1;
                        {error, _TryE1} -> erlang:throw({'__bp_region', _TryE1})
                    end, case lookup(B) of
                        {ok, _TryV2} -> _TryV2;
                        {error, _TryE2} -> erlang:throw({'__bp_region', _TryE2})
                    end)
            end
        catch
            throw:{'__bp_region', _RgE0} -> erlang:throw({'__bp_try', {error, bp_load_cases_try_block_catch_rethrow@main@@ConfigError__v__invalid}})
        end}
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

port(Key) ->
    try
        P = try
            case true of
                _ ->
                    case lookup(Key) of
                        {ok, _TryV1} -> _TryV1;
                        {error, _TryE1} -> erlang:throw({'__bp_region', _TryE1})
                    end
            end
        catch
            throw:{'__bp_region', E} -> case true of
                _ ->
                    erlang:throw({'__bp_try', {error, {bp_load_cases_try_block_catch_rethrow@main@@ConfigError__v__missing, E}}})
            end
        end,
        {ok, '__bp_int'((P + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:24:14">>)}
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

show(R) ->
    case R of
        {ok, V} ->
            erlang:integer_to_binary(V);
        {error, E} ->
            case E of
                {bp_load_cases_try_block_catch_rethrow@main@@ConfigError__v__missing, Key} ->
                    <<"missing ", ('__bp_text'(Key))/binary>>;
                bp_load_cases_try_block_catch_rethrow@main@@ConfigError__v__invalid ->
                    <<"invalid">>
            end
    end.

main() ->
    '__bp_print'([show(sum(<<"port">>, <<"offset">>))]),
    '__bp_print'([show(sum(<<"port">>, <<"host">>))]),
    '__bp_print'([show(port(<<"port">>))]),
    '__bp_print'([show(port(<<"host">>))]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/try_block_catch_rethrow|*">>.

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

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

'__bp_priv__lookup'(A0) -> lookup(A0).

'__bp_priv__sum'(A0, A1) -> sum(A0, A1).

'__bp_priv__port'(A0) -> port(A0).

'__bp_priv__show'(A0) -> show(A0).

-module(bp_load_cases_try_in_catch_body_propagates@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__primary'/1, '__bp_priv__backup'/1, '__bp_priv__load'/1, '__bp_priv__either'/1, '__bp_priv__show'/1]).

%%% Decision 595 (6) — a `try` in the handler's body belongs to the enclosing

%%% region or the function, never to its own `catch`: `backup`'s failure leaves

%%% `load` as its `Error`, and in `either` it reaches the outer region's

%%% `catch`.

primary(N) ->
    case (N > 10) of
        true ->
            {error, <<"primary down">>};
        _ ->
            {ok, N}
    end.

backup(N) ->
    case (N > 20) of
        true ->
            {error, <<"backup down">>};
        _ ->
            {ok, '__bp_int'((N * 100), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:15:14">>)}
    end.

load(N) ->
    try
        V = try
            case true of
                _ ->
                    case primary(N) of
                        {ok, _TryV1} -> _TryV1;
                        {error, _TryE1} -> erlang:throw({'__bp_region', _TryE1})
                    end
            end
        catch
            throw:{'__bp_region', _RgE0} -> case true of
                _ ->
                    case backup(N) of
                        {ok, _TryV2} -> _TryV2;
                        {error, _TryE2} -> erlang:throw({'__bp_try', {error, _TryE2}})
                    end
            end
        end,
        {ok, '__bp_int'((V + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:20:14">>)}
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

either(N) ->
    try
        case true of
            _ ->
                try
                    case true of
                        _ ->
                            case primary(N) of
                                {ok, _TryV2} -> _TryV2;
                                {error, _TryE2} -> erlang:throw({'__bp_region', _TryE2})
                            end
                    end
                catch
                    throw:{'__bp_region', _RgE1} -> case true of
                        _ ->
                            case backup(N) of
                                {ok, _TryV3} -> _TryV3;
                                {error, _TryE3} -> erlang:throw({'__bp_region', _TryE3})
                            end
                    end
                end
        end
    catch
        throw:{'__bp_region', _RgE0} -> (-1)
    end.

show(R) ->
    case R of
        {ok, V} ->
            erlang:integer_to_binary(V);
        {error, E} ->
            E
    end.

main() ->
    '__bp_print'([show(load(5))]),
    '__bp_print'([show(load(15))]),
    '__bp_print'([show(load(25))]),
    '__bp_print'([either(5)]),
    '__bp_print'([either(15)]),
    '__bp_print'([either(25)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/try_in_catch_body_propagates|*">>.

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

'__bp_priv__primary'(A0) -> primary(A0).

'__bp_priv__backup'(A0) -> backup(A0).

'__bp_priv__load'(A0) -> load(A0).

'__bp_priv__either'(A0) -> either(A0).

'__bp_priv__show'(A0) -> show(A0).

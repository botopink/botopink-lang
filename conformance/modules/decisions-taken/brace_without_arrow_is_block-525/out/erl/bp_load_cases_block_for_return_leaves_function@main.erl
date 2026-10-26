-module(bp_load_cases_block_for_return_leaves_function@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__firstAbove'/2, '__bp_priv__labelOf'/1]).

%%% Decision 525 — a `return` from a `for` inside a block leaves the

%%% enclosing function, on every target; the block's value is its tail on

%%% every other path.

firstAbove(Xs, Limit) ->
    try
        Found = case true of
            _ ->
                lists:foreach(fun(X) ->
                    case (X > Limit) of
                        true ->
                            erlang:throw({'__bp_try', '__bp_int'((X * 100), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:10:37">>)});
                        _ -> ok
                    end
                end, Xs),
                (-1)
        end,
        '__bp_int'((Found * 10), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:14:18">>)
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

labelOf(Xs) ->
    try
        Hit = case true of
            _ ->
                lists:foreach(fun(S) ->
                    case (S =/= <<"a">>) of
                        true ->
                            erlang:throw({'__bp_try', <<"[", ('__bp_text'(S))/binary, "]">>});
                        _ -> ok
                    end
                end, Xs),
                <<"none">>
        end,
        <<"<", ('__bp_text'(Hit))/binary, ">">>
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

main() ->
    '__bp_print'([firstAbove([1, 7, 9], 5)]),
    '__bp_print'([firstAbove([1, 2], 5)]),
    '__bp_print'([labelOf([<<"a">>, <<"abc">>, <<"abcd">>])]),
    '__bp_print'([labelOf([<<"a">>])]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/block_for_return_leaves_function|*">>.

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

'__bp_priv__firstAbove'(A0, A1) -> firstAbove(A0, A1).

'__bp_priv__labelOf'(A0) -> labelOf(A0).

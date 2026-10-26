-module(bp_load_cases_bigint_in_containers@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__three'/0]).

%% behavior array

array_range(Start, Stop) ->
    case ((Stop - Start) =< 0) of
        true ->
            [];
        false ->
            case ((Stop - Start) =:= 1) of
                true ->
                    [Start];
                false ->
                    Count = (Stop - Start),
                    Low = array_range(Start, (Start + (Count div 2))),
                    High = array_range((Start + (Count div 2)), Stop),
                    '__bp_prim_append'(Low, High)
            end
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Half = array_repeat(Value, (Times div 2)),
            case ((Times rem 2) =:= 0) of
                true ->
                    '__bp_prim_append'(Half, Half);
                false ->
                    '__bp_prim_append'('__bp_prim_append'(Half, Half), [Value])
            end
    end.

%%% Decision 332 — a `bigint` held by a record field, a `?bigint` field, a tuple, an array and an

%%% optional prints its digits and compares by value on the four targets: wasm's slot holds the

%%% block's address, printed by the `n` shape code and compared by std-wasm's `bigint.compare` (as an `i32` word,

%%% the address printed and two equal values built apart compared unequal).

%% type Ledger: total, last

three() ->
    (1 + 2).

main() ->
    L = {bp_load_cases_bigint_in_containers@main@@Ledger, (123456789012345678901234567890 * 10), undefined},
    '__bp_print'([L]),
    '__bp_print'([(erlang:element(2, L) + 1)]),
    '__bp_print'([({bp_load_cases_bigint_in_containers@main@@Ledger, three(), three()} =:= {bp_load_cases_bigint_in_containers@main@@Ledger, 3, 3})]),
    '__bp_print'([({bp_load_cases_bigint_in_containers@main@@Ledger, three(), undefined} =:= {bp_load_cases_bigint_in_containers@main@@Ledger, 3, 3})]),
    Pair = {(three() * 1000000000000000000000), <<"big">>},
    '__bp_print'([Pair]),
    '__bp_print'([(Pair =:= {3000000000000000000000, <<"big">>})]),
    Xs = [three(), 40000000000000000000000],
    '__bp_print'([Xs]),
    '__bp_print'([(Xs =:= [3, 40000000000000000000000])]),
    '__bp_print'([(fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Xs, 1)]),
    '__bp_print'([(fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Xs, 5)]),
    Total = 0,
    Total@3 = lists:foldl(fun(X, Total@1) ->
        Total@2 = Total@1 + X,
        Total@2
    end, Total, Xs),
    '__bp_print'([Total@3]),
    '__bp_print'([lists:foldl(fun(__X, __A) -> (fun(Acc, X@1) ->
        (Acc * X@1)
    end)(__A, __X) end, 1, Xs)]),
    Maybe = case (Total@3 > 0) of
        true ->
            Total@3;
        false ->
            undefined
    end,
    '__bp_print'([Maybe]),
    '__bp_print'([(Maybe =:= (three() + 40000000000000000000000))]),
    Label = case three() of
        3 ->
            <<"three">>;
        _ ->
            <<"other">>
    end,
    '__bp_print'([Label]),
    Band = case Total@3 of
        _Rng0 when (_Rng0 >= 0), (_Rng0 =< 9) ->
            <<"small">>;
        _ ->
            <<"large">>
    end,
    '__bp_print'([Band]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/bigint_in_containers|*">>.

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

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

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).

'__bp_priv__three'() -> three().

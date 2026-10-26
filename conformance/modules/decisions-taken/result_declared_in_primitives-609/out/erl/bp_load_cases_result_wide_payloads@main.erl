-module(bp_load_cases_result_wide_payloads@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__half'/1, '__bp_priv__triple'/1, '__bp_priv__halfOr'/1, '__bp_priv__described'/1, '__bp_priv__quarter'/1, '__bp_priv__tripleOrZero'/1]).

%%% 144 B-22 — a `Result` whose `Ok` is an `f64` or an `i64` keeps the whole value through every

%%% reader, on every target: `unwrapOr`, a `case` arm's binder, `try`, `try … catch` and `map`.

half(N) ->
    case (N < 0.0) of
        true ->
            {error, <<"negative">>};
        _ ->
            {ok, (N / 2.0)}
    end.

triple(N) ->
    case (N < 0) of
        true ->
            {error, <<"negative">>};
        _ ->
            {ok, '__bp_int'((N * 3), -9223372036854775808, 9223372036854775807, <<"integer overflow: * on i64 at src/main.bp:13:14">>)}
    end.

halfOr(N) ->
    case half(N) of
        {ok, V} ->
            V;
        {error, _} ->
            (-1.0)
    end.

described(N) ->
    case triple(N) of
        {ok, V} ->
            erlang:integer_to_binary(V);
        {error, E} ->
            E
    end.

quarter(N) ->
    case half(N) of
        {ok, H} ->
            {ok, (H / 2.0)};
        {error, _TryE0} -> {error, _TryE0}
    end.

tripleOrZero(N) ->
    case triple(N) of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            0
    end.

main() ->
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> (0.0) end end)(half(3.0))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, __BpV1} -> __BpV1; _ -> (0.5) end end)(half((-3.0)))]),
    '__bp_print'([halfOr(5.0)]),
    '__bp_print'([halfOr((-5.0))]),
    '__bp_print'([described(3002399751580331)]),
    '__bp_print'([described((-1))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, __BpV2} -> __BpV2; _ -> (0) end end)(triple(3002399751580331))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, __BpV3} -> __BpV3; _ -> (0.0) end end)(quarter(10.0))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {error, _} -> true; _ -> false end end)(quarter((-10.0)))]),
    '__bp_print'([tripleOrZero(7)]),
    '__bp_print'([tripleOrZero((-7))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, __BpV5} -> __BpV5; _ -> (0.0) end end)((fun(__BpR) -> case __BpR of {ok, __BpV6} -> {ok, (fun(V) ->
        (V + 0.25)
    end)(__BpV6)}; _ -> __BpR end end)(half(8.0)))]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/result_wide_payloads|*">>.

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

'__bp_priv__triple'(A0) -> triple(A0).

'__bp_priv__halfOr'(A0) -> halfOr(A0).

'__bp_priv__described'(A0) -> described(A0).

'__bp_priv__quarter'(A0) -> quarter(A0).

'__bp_priv__tripleOrZero'(A0) -> tripleOrZero(A0).

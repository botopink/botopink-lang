-module(bp_load_cases_catch_region_covers_left_side@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__half'/1, '__bp_priv__both'/2, '__bp_priv__next'/1]).

%%% Decision 595 (2) — without a block the region is the whole expression left

%%% of the `catch` (537 (2)): `(try a) + (try b) catch 0` sends both failures to

%%% the one `catch`, and `try half(n) + 1 catch 0` is

%%% `((try half(n)) + 1) catch 0`.

half(N) ->
    case ((N rem 2) =/= 0) of
        true ->
            {error, <<"odd">>};
        _ ->
            {ok, '__bp_int'((N div 2), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/main.bp:10:14">>)}
    end.

both(A, B) ->
    try
        '__bp_add'((case half(A) of
            {ok, _TryV1} -> _TryV1;
            {error, _TryE1} -> erlang:throw({'__bp_region', _TryE1})
        end), (case half(B) of
            {ok, _TryV2} -> _TryV2;
            {error, _TryE2} -> erlang:throw({'__bp_region', _TryE2})
        end))
    catch
        throw:{'__bp_region', _RgE0} -> 0
    end.

next(N) ->
    try
        '__bp_int'((case half(N) of
            {ok, _TryV1} -> _TryV1;
            {error, _TryE1} -> erlang:throw({'__bp_region', _TryE1})
        end + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:18:24">>)
    catch
        throw:{'__bp_region', _RgE0} -> 0
    end.

main() ->
    '__bp_print'([both(4, 6)]),
    '__bp_print'([both(3, 6)]),
    '__bp_print'([both(4, 7)]),
    '__bp_print'([next(10)]),
    '__bp_print'([next(9)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/catch_region_covers_left_side|*">>.

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

'__bp_priv__both'(A0, A1) -> both(A0, A1).

'__bp_priv__next'(A0) -> next(A0).

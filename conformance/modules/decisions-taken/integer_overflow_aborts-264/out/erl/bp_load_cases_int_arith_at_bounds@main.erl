-module(bp_load_cases_int_arith_at_bounds@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__i32Of'/1, '__bp_priv__i8Of'/1, '__bp_priv__u32Of'/1, '__bp_priv__i64Of'/1]).

%%% Decision 264's other half: a result AT its type's bound is a value, never

%%% an abort — `i32`'s and `i8`'s two ends, `u32`'s maximum and zero, and an

%%% `i64` at commonJS's exact bound `2^53 − 1`, each reached by arithmetic.

i32Of(X) ->
    X.

i8Of(X) ->
    X.

u32Of(X) ->
    X.

i64Of(X) ->
    X.

main() ->
    '__bp_print'(['__bp_int'((i32Of(2147483646) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:24:29">>)]),
    '__bp_print'(['__bp_int'((i32Of((-2147483647)) - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/main.bp:25:30">>)]),
    '__bp_print'(['__bp_int'((i32Of((-46341)) * 46340), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:26:25">>)]),
    '__bp_print'(['__bp_int'((-i32Of((-2147483647))), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/main.bp:27:11">>)]),
    '__bp_print'(['__bp_int'((i8Of(126) + 1), -128, 127, <<"integer overflow: + on i8 at src/main.bp:28:21">>)]),
    '__bp_print'(['__bp_int'((i8Of((-127)) - 1), -128, 127, <<"integer overflow: - on i8 at src/main.bp:29:22">>)]),
    '__bp_print'(['__bp_int'((u32Of(4294967294) + 1), 0, 4294967295, <<"integer overflow: + on u32 at src/main.bp:30:29">>)]),
    '__bp_print'(['__bp_int'((u32Of(1) - 1), 0, 4294967295, <<"integer overflow: - on u32 at src/main.bp:31:20">>)]),
    '__bp_print'(['__bp_int'((i64Of(9007199254740990) + 1), -9223372036854775808, 9223372036854775807, <<"integer overflow: + on i64 at src/main.bp:32:35">>)]),
    '__bp_print'(['__bp_int'((-i64Of(9007199254740991)), -9223372036854775808, 9223372036854775807, <<"integer overflow: - on i64 at src/main.bp:33:11">>)]),
    N = 2147483640,
    N@1 = '__bp_int'(N + 7, -2147483648, 2147483647, <<"integer overflow: += on i32 at src/main.bp:35:5">>),
    '__bp_print'([N@1]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/int_arith_at_bounds|*">>.

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

'__bp_priv__i32Of'(A0) -> i32Of(A0).

'__bp_priv__i8Of'(A0) -> i8Of(A0).

'__bp_priv__u32Of'(A0) -> u32Of(A0).

'__bp_priv__i64Of'(A0) -> i64Of(A0).

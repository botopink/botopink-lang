-module(bp_load_cases_integer_conversions_exact@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__grow'/2]).

%% behavior Integer

%%% 02-std-and-packaging/97-std-dedupe step 13, decision 319 — the explicit integer conversions

%%% `toI32()`, `toI64()`, `toU32()`, `toU64()` and `toF64()` are std's `Integer` methods, and a

%%% value that fits converts exactly on every target: the type's own bounds, a value past 2^53

%%% (a `BigInt` on commonJS) and an `f64` that holds the integer exactly. The parent declared none

%%% (`toI32` was no method of `i64`). A value that does not fit aborts:

%%% `run/integer_conversion_to_i32_aborts`, `run/integer_conversion_to_f64_inexact_aborts`.

grow(A, B) ->
    '__bp_int'((A + B), -9223372036854775808, 9223372036854775807, <<"integer overflow: + on i64 at src/main.bp:11:14">>).

main() ->
    Small = 2147483647,
    '__bp_print'([(fun(__V) when __V >= -2147483648, __V =< 2147483647 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI32: ", (integer_to_binary(__V))/binary, " does not fit i32">>}) end)(Small)]),
    '__bp_print'([(fun(__V) when __V >= -2147483648, __V =< 2147483647 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI32: ", (integer_to_binary(__V))/binary, " does not fit i32">>}) end)(grow('__bp_int'((-Small), -9223372036854775808, 9223372036854775807, <<"integer overflow: - on i64 at src/main.bp:17:16">>), (-1)))]),
    '__bp_print'([(fun(__V) when __V >= 0, __V =< 4294967295 -> __V; (__V) -> erlang:error({integer_overflow, <<"toU32: ", (integer_to_binary(__V))/binary, " does not fit u32">>}) end)(4294967295)]),
    '__bp_print'([(fun(__V) when __V >= 0, __V =< 4294967295 -> __V; (__V) -> erlang:error({integer_overflow, <<"toU32: ", (integer_to_binary(__V))/binary, " does not fit u32">>}) end)(0)]),
    Big = grow(9007199254740991, 2),
    '__bp_print'([(fun(__V) when __V >= 0, __V < (1 bsl 64) -> __V; (__V) -> erlang:error({integer_overflow, <<"toU64: ", (integer_to_binary(__V))/binary, " does not fit u64">>}) end)(Big)]),
    '__bp_print'([(fun(__V) when __V >= -9223372036854775807 - 1, __V =< 9223372036854775807 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI64: ", (integer_to_binary(__V))/binary, " does not fit i64">>}) end)(Big)]),
    '__bp_print'([(fun(__V) when __V >= -9223372036854775807 - 1, __V =< 9223372036854775807 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI64: ", (integer_to_binary(__V))/binary, " does not fit i64">>}) end)(9223372036854775807)]),
    '__bp_print'([(fun(__V) when __V >= 0, __V < (1 bsl 64) -> __V; (__V) -> erlang:error({integer_overflow, <<"toU64: ", (integer_to_binary(__V))/binary, " does not fit u64">>}) end)(18446744073709551615)]),
    '__bp_print'([((fun(__V) -> __F = float(__V), case trunc(__F) =:= __V of true -> __F; false -> erlang:error({integer_overflow, <<"toF64: ", (integer_to_binary(__V))/binary, " has no exact f64">>}) end end)(grow(Big, 1)) =:= 9007199254740994.0)]),
    '__bp_print'([erlang:integer_to_binary((fun(__V) when __V >= 0, __V < (1 bsl 64) -> __V; (__V) -> erlang:error({integer_overflow, <<"toU64: ", (integer_to_binary(__V))/binary, " does not fit u64">>}) end)((fun(__V) when __V >= -9223372036854775807 - 1, __V =< 9223372036854775807 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI64: ", (integer_to_binary(__V))/binary, " does not fit i64">>}) end)(9223372036854775807)))]),
    '__bp_print'([((fun(__V) -> __F = float(__V), case trunc(__F) =:= __V of true -> __F; false -> erlang:error({integer_overflow, <<"toF64: ", (integer_to_binary(__V))/binary, " has no exact f64">>}) end end)(grow((-9007199254740991), 0)) =:= (-9007199254740991.0))]),
    '__bp_print'(['__bp_int'(((fun(__V) when __V >= -9223372036854775807 - 1, __V =< 9223372036854775807 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI64: ", (integer_to_binary(__V))/binary, " does not fit i64">>}) end)(7) + 9007199254740991), -9223372036854775808, 9223372036854775807, <<"integer overflow: + on i64 at src/main.bp:28:21">>)]),
    '__bp_print'([((fun(__V) -> __F = float(__V), case trunc(__F) =:= __V of true -> __F; false -> erlang:error({integer_overflow, <<"toF64: ", (integer_to_binary(__V))/binary, " has no exact f64">>}) end end)(7) / 2.0)]),
    '__bp_print'([(fun(__V) when __V >= -9223372036854775807 - 1, __V =< 9223372036854775807 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI64: ", (integer_to_binary(__V))/binary, " does not fit i64">>}) end)(4000000000)]),
    '__bp_print'(['__bp_int'((-(fun(__V) when __V >= -2147483648, __V =< 2147483647 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI32: ", (integer_to_binary(__V))/binary, " does not fit i32">>}) end)((fun(__V) when __V >= -9223372036854775807 - 1, __V =< 9223372036854775807 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI64: ", (integer_to_binary(__V))/binary, " does not fit i64">>}) end)(5))), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/main.bp:31:11">>)]),
    '__bp_print'([(fun(__V) when __V >= -2147483648, __V =< 2147483647 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI32: ", (integer_to_binary(__V))/binary, " does not fit i32">>}) end)((fun(__V) when __V >= 0, __V < (1 bsl 64) -> __V; (__V) -> erlang:error({integer_overflow, <<"toU64: ", (integer_to_binary(__V))/binary, " does not fit u64">>}) end)(1234567))]),
    '__bp_print'([((fun(__V) -> __F = float(__V), case trunc(__F) =:= __V of true -> __F; false -> erlang:error({integer_overflow, <<"toF64: ", (integer_to_binary(__V))/binary, " has no exact f64">>}) end end)(4611686018427387904) =:= 4611686018427387904.0)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/integer_conversions_exact|*">>.

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

'__bp_priv__grow'(A0, A1) -> grow(A0, A1).

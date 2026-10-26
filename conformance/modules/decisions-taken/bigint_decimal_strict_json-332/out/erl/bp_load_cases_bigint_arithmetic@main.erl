-module(bp_load_cases_bigint_arithmetic@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__power'/2]).

%% behavior bigint

%%% Decision 332 — `bigint` is an integer of any size, one value on the four targets: erlang and

%%% beam hold the VM's integer, commonJS a `BigInt`, wasm its runtime library. `+ - * / %`, unary

%%% `-`, `+=`, the comparisons and `==` over two `bigint`s never overflow; `/` truncates toward

%%% zero and `%` takes the dividend's sign; `bigint.of` / `bigint.parse` cross in, `toString`,

%%% `toI64` and `toF64` out. The parent binary refused the `n` suffix.

power(Base, Times) ->
    X = 1,
    I = 0,
    {X@3, I@3} = (fun __BpLoop({X@1, I@1}) ->
        case (I@1 < Times) of
            true ->
                X@2 = (X@1 * Base),
                I@2 = '__bp_int'(I@1 + 1, -2147483648, 2147483647, <<"integer overflow: += on i32 at src/main.bp:14:9">>),
                __BpLoop({X@2, I@2});
            _ -> {X@1, I@1}
        end
    end)({X, I}),
    X@3.

main() ->
    Two = 2,
    Top = power(Two, 101),
    '__bp_print'([Top]),
    A = 1234567890123456789012345678901234567890,
    B = 9876543210987654321098765432109876543210,
    '__bp_print'([(A * B)]),
    '__bp_print'([(B - (A * 8))]),
    '__bp_print'([(A + B)]),
    '__bp_print'([((-7) div '__bp_nz'(2, <<"integer division by zero: / on bigint at src/main.bp:28:15">>))]),
    '__bp_print'([(7 div '__bp_nz'((-2), <<"integer division by zero: / on bigint at src/main.bp:29:14">>))]),
    '__bp_print'([((-7) rem '__bp_nz'(2, <<"integer division by zero: % on bigint at src/main.bp:30:15">>))]),
    '__bp_print'([(7 rem '__bp_nz'((-2), <<"integer division by zero: % on bigint at src/main.bp:31:14">>))]),
    '__bp_print'([((-B) div '__bp_nz'(A, <<"integer division by zero: / on bigint at src/main.bp:32:14">>))]),
    '__bp_print'([((-B) rem '__bp_nz'(A, <<"integer division by zero: % on bigint at src/main.bp:33:14">>))]),
    '__bp_print'([(((A * B) div '__bp_nz'(B, <<"integer division by zero: / on bigint at src/main.bp:34:17">>)) =:= A)]),
    '__bp_print'([((((A * B) + 7)) rem '__bp_nz'(B, <<"integer division by zero: % on bigint at src/main.bp:35:24">>))]),
    '__bp_print'([(Top div '__bp_nz'(1000000007, <<"integer division by zero: / on bigint at src/main.bp:36:15">>))]),
    '__bp_print'([(Top rem '__bp_nz'(1000000007, <<"integer division by zero: % on bigint at src/main.bp:37:15">>))]),
    '__bp_print'([(A < B)]),
    '__bp_print'([(B =< A)]),
    '__bp_print'([((-B) < A)]),
    '__bp_print'([(A =:= 1234567890123456789012345678901234567890)]),
    '__bp_print'([(A =/= B)]),
    '__bp_print'([erlang:integer_to_binary(Top)]),
    '__bp_print'([<<"2^101 = ", ('__bp_text'(Top))/binary>>]),
    Sum = 0,
    Sum@1 = Sum + A,
    Sum@2 = Sum@1 + B,
    '__bp_print'([Sum@2]),
    '__bp_print'([(-Sum@2)]),
    '__bp_print'([((0 - Sum@2) + Sum@2)]),
    '__bp_print'([(9223372036854775807 + 1)]),
    '__bp_print'([('__bp_int'(((-9223372036854775807) - 1), -9223372036854775808, 9223372036854775807, <<"integer overflow: - on i64 at src/main.bp:52:43">>) - 1)]),
    '__bp_print'([((-5) * 3)]),
    '__bp_print'([12]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> (0) end end)((fun(__S) -> __D = case __S of <<"-", __R/binary>> -> __R; <<"+", __R/binary>> -> __R; _ -> __S end, case (__D =/= <<>>) andalso lists:all(fun(__C) -> (__C >= 48) andalso (__C =< 57) end, binary_to_list(__D)) of true -> {ok, binary_to_integer(__S)}; false -> {error, <<"bigint.parse: ", 34, __S/binary, 34, " is not an integer">>} end end)(<<"-123456789012345678901234567890">>))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, __BpV1} -> __BpV1; _ -> (0) end end)((fun(__S) -> __D = case __S of <<"-", __R/binary>> -> __R; <<"+", __R/binary>> -> __R; _ -> __S end, case (__D =/= <<>>) andalso lists:all(fun(__C) -> (__C >= 48) andalso (__C =< 57) end, binary_to_list(__D)) of true -> {ok, binary_to_integer(__S)}; false -> {error, <<"bigint.parse: ", 34, __S/binary, 34, " is not an integer">>} end end)(<<"+42">>))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, __BpV2} -> __BpV2; _ -> ((-1)) end end)((fun(__S) -> __D = case __S of <<"-", __R/binary>> -> __R; <<"+", __R/binary>> -> __R; _ -> __S end, case (__D =/= <<>>) andalso lists:all(fun(__C) -> (__C >= 48) andalso (__C =< 57) end, binary_to_list(__D)) of true -> {ok, binary_to_integer(__S)}; false -> {error, <<"bigint.parse: ", 34, __S/binary, 34, " is not an integer">>} end end)(<<"12x">>))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, __BpV3} -> __BpV3; _ -> ((-2)) end end)((fun(__S) -> __D = case __S of <<"-", __R/binary>> -> __R; <<"+", __R/binary>> -> __R; _ -> __S end, case (__D =/= <<>>) andalso lists:all(fun(__C) -> (__C >= 48) andalso (__C =< 57) end, binary_to_list(__D)) of true -> {ok, binary_to_integer(__S)}; false -> {error, <<"bigint.parse: ", 34, __S/binary, 34, " is not an integer">>} end end)(<<"">>))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, __BpV4} -> __BpV4; _ -> ((-3)) end end)((fun(__S) -> __D = case __S of <<"-", __R/binary>> -> __R; <<"+", __R/binary>> -> __R; _ -> __S end, case (__D =/= <<>>) andalso lists:all(fun(__C) -> (__C >= 48) andalso (__C =< 57) end, binary_to_list(__D)) of true -> {ok, binary_to_integer(__S)}; false -> {error, <<"bigint.parse: ", 34, __S/binary, 34, " is not an integer">>} end end)(<<"-">>))]),
    Near = 4611686018427387904,
    '__bp_print'(['__bp_int'(((fun(__V) when __V >= -9223372036854775807 - 1, __V =< 9223372036854775807 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI64: ", (integer_to_binary(__V))/binary, " does not fit i64">>}) end)(Near) + 1), -9223372036854775808, 9223372036854775807, <<"integer overflow: + on i64 at src/main.bp:61:24">>)]),
    '__bp_print'([(fun(__V) when __V >= -9223372036854775807 - 1, __V =< 9223372036854775807 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI64: ", (integer_to_binary(__V))/binary, " does not fit i64">>}) end)((((-Near) * 2)))]),
    '__bp_print'([(fun(__V) -> case abs(__V) =< ((1 bsl 1024) - (1 bsl 971)) of true -> __F = float(__V), case trunc(__F) =:= __V of true -> __F; false -> erlang:error({integer_overflow, <<"toF64: ", (integer_to_binary(__V))/binary, " has no exact f64">>}) end; false -> erlang:error({integer_overflow, <<"toF64: ", (integer_to_binary(__V))/binary, " has no exact f64">>}) end end)((1024))]),
    '__bp_print'([((fun(__V) -> case abs(__V) =< ((1 bsl 1024) - (1 bsl 971)) of true -> __F = float(__V), case trunc(__F) =:= __V of true -> __F; false -> erlang:error({integer_overflow, <<"toF64: ", (integer_to_binary(__V))/binary, " has no exact f64">>}) end; false -> erlang:error({integer_overflow, <<"toF64: ", (integer_to_binary(__V))/binary, " has no exact f64">>}) end end)(((power(Two, 80) * 3))) =:= 3626777458843887524118528.0)]),
    '__bp_print'([(16#FF * 16#100)]),
    '__bp_print'([(1_000_000 * 1_000_000)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/bigint_arithmetic|*">>.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

-compile({inline,['__bp_nz'/2]}).
'__bp_nz'(B, What) when B == 0 -> erlang:error({panic, What});
'__bp_nz'(B, _) -> B.

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

'__bp_priv__power'(A0, A1) -> power(A0, A1).

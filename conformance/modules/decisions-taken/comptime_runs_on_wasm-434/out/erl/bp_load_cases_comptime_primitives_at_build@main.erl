-module(bp_load_cases_comptime_primitives_at_build@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__ints'/0, '__bp_priv__exact'/0, '__bp_priv__strs'/0, '__bp_priv__floats'/0, '__bp_priv__arrs'/0, '__bp_priv__divs'/0, '__bp_priv__string_slice'/3]).

%% behavior string

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

%% behavior Integer

%%% Decisions 331, 434 (5) — a primitive computed at build answers what the

%%% program computes when it runs, one answer for every target: integer

%%% conversions (`1000.toI64()` used to raise `integer_overflow` at build,

%%% its bound written `1 bsl 63`, which the comptime runtime's 64-bit

%%% integers cannot hold), string methods, float arithmetic and text, array

%%% methods and integer division. Each family is computed under `comptime`

%%% and again at run time, and the two compared.

ints() ->
    A = 1000,
    B = 9007199254740993,
    C = 9223372036854775807,
    <<('__bp_text'(erlang:integer_to_binary((fun(__V) when __V >= -9223372036854775807 - 1, __V =< 9223372036854775807 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI64: ", (integer_to_binary(__V))/binary, " does not fit i64">>}) end)(A))))/binary, " ", ('__bp_text'(erlang:integer_to_binary(B)))/binary, " ", ('__bp_text'(erlang:integer_to_binary(('__bp_int'((B - 1), -9223372036854775808, 9223372036854775807, <<"integer overflow: - on i64 at src/main.bp:19:14">>)))))/binary, " ", ('__bp_text'(erlang:integer_to_binary((fun(__V) when __V >= 0, __V =< 4294967295 -> __V; (__V) -> erlang:error({integer_overflow, <<"toU32: ", (integer_to_binary(__V))/binary, " does not fit u32">>}) end)(A))))/binary, " ", ('__bp_text'(erlang:integer_to_binary((fun(__V) when __V >= -9223372036854775807 - 1, __V =< 9223372036854775807 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI64: ", (integer_to_binary(__V))/binary, " does not fit i64">>}) end)(B))))/binary, " ", ('__bp_text'(erlang:integer_to_binary((fun(__V) when __V >= -9223372036854775807 - 1, __V =< 9223372036854775807 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI64: ", (integer_to_binary(__V))/binary, " does not fit i64">>}) end)(C))))/binary>>.

exact() ->
    A = 1000,
    ((fun(__V) -> __F = float(__V), case trunc(__F) =:= __V of true -> __F; false -> erlang:error({integer_overflow, <<"toF64: ", (integer_to_binary(__V))/binary, " has no exact f64">>}) end end)(A) =:= 1000.0).

strs() ->
    S = <<"  H\x{C3}\x{A9}llo, World  ">>,
    <<('__bp_text'(string:uppercase(string:trim(S))))/binary, "|", ('__bp_text'(string:lowercase(string:trim(S))))/binary, "|", ('__bp_text'(erlang:integer_to_binary(erlang:length(unicode:characters_to_list(S)))))/binary, "|", ('__bp_text'(iolist_to_binary(lists:join(<<"+">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, (fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(string:trim(S), <<", ">>))))))/binary, "|", ('__bp_text'(string_slice(string:trim(S), 1, 4)))/binary, "|", ('__bp_text'(erlang:integer_to_binary((fun(__S, __X) -> case __X of <<>> -> 0; _ -> case binary:match(__S, __X) of nomatch -> -1; {__P, _} -> erlang:length(unicode:characters_to_list(binary:part(__S, 0, __P))) end end end)(S, <<"W">>))))/binary, "|", ('__bp_text'(erlang:atom_to_binary((string:prefix(string:trim(S), <<"H">>) =/= nomatch))))/binary, "|", ('__bp_text'(iolist_to_binary(string:replace(string:trim(S), <<"l">>, <<"L">>))))/binary>>.

floats() ->
    X = 3.5,
    <<('__bp_text'(float_to_binary(((X / 2.0)), [short])))/binary, " ", ('__bp_text'(float_to_binary(((1.0 / 3.0)), [short])))/binary, " ", ('__bp_text'(float_to_binary(((0.1 + 0.2)), [short])))/binary, " ", ('__bp_text'(float_to_binary(((2.0 * 1.0e-7)), [short])))/binary>>.

arrs() ->
    Xs = [3, 1, 2],
    <<('__bp_text'(iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(X) ->
        '__bp_int'((X * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:65:28">>)
    end, Xs))))))/binary, " ", ('__bp_text'(iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:reverse(Xs))))))/binary, " ", ('__bp_text'(erlang:integer_to_binary(erlang:length(Xs))))/binary, " ", ('__bp_text'(iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:filter(fun(X) ->
        (X > 1)
    end, Xs))))))/binary, " ", ('__bp_text'(erlang:integer_to_binary(lists:foldl(fun(__X, __A) -> (fun(Acc, X) ->
        '__bp_add'(Acc, X)
    end)(__A, __X) end, 0, Xs))))/binary, " ", ('__bp_text'(erlang:atom_to_binary(lists:member(2, Xs))))/binary>>.

divs() ->
    <<('__bp_text'(erlang:integer_to_binary(('__bp_int'((7 div 2), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/main.bp:79:15">>)))))/binary, " ", ('__bp_text'(erlang:integer_to_binary(('__bp_int'((('__bp_int'((0 - 7), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/main.bp:81:15">>)) div 2), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/main.bp:81:20">>)))))/binary, " ", ('__bp_text'(erlang:integer_to_binary(((7 rem 3)))))/binary, " ", ('__bp_text'(erlang:integer_to_binary(((('__bp_int'((0 - 7), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/main.bp:85:15">>)) rem 3)))))/binary>>.

main() ->
    I = <<"1000 9007199254740993 9007199254740992 1000 9007199254740993 9223372036854775807">>,
    '__bp_print'([I]),
    '__bp_print'([(I =:= ints())]),
    '__bp_print'([true]),
    S = <<"H\x{C3}\x{89}LLO, WORLD|h\x{C3}\x{A9}llo, world|16|H\x{C3}\x{A9}llo+World|\x{C3}\x{A9}ll|9|true|H\x{C3}\x{A9}Llo, World">>,
    '__bp_print'([S]),
    '__bp_print'([(S =:= strs())]),
    F = <<"1.75 0.3333333333333333 0.30000000000000004 2.0e-7">>,
    '__bp_print'([F]),
    '__bp_print'([(F =:= floats())]),
    A = <<"6,2,4 2,1,3 3 3,2 6 true">>,
    '__bp_print'([A]),
    '__bp_print'([(A =:= arrs())]),
    D = <<"3 -3 1 -1">>,
    '__bp_print'([D]),
    '__bp_print'([(D =:= divs())]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/comptime_primitives_at_build|*">>.

string_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            (fun(__S, __A, __E) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, __F = case __E < 0 of true -> erlang:max(__N + __E, 0); false -> erlang:min(__E, __N) end, unicode:characters_to_binary(lists:sublist(__L, __B + 1, erlang:max(__F - __B, 0))) end)(Self, Start, End);
        false ->
            (fun(__S, __A) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, unicode:characters_to_binary(lists:nthtail(__B, __L)) end)(Self, Start)
    end.

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

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

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).

'__bp_priv__ints'() -> ints().

'__bp_priv__exact'() -> exact().

'__bp_priv__strs'() -> strs().

'__bp_priv__floats'() -> floats().

'__bp_priv__arrs'() -> arrs().

'__bp_priv__divs'() -> divs().

'__bp_priv__string_slice'(A0, A1, A2) -> string_slice(A0, A1, A2).

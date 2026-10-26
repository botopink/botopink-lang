-module(bp_load_cases_decorator_expr_value@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, 'scale_$0'/1, 'scale_$1'/1, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__array_first'/1]).

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

%%% Decision 364 (2) — every `comptime` parameter is `comptime x: @Expr<T>`,

%%% and `x.value` answers the argument's value at build when it is known and

%%% `T` is data: a string, a number, a `bool`, a variant, a record, a field

%%% key, an array. The same `.value` reads an ordinary function's `comptime`

%%% parameter (the call specialised) and a template's literal without holes.

%% import Type, Type__Field

%% type Level
%%   Low
%%   High

%% type Limits: min, max

%% type City: code, name

main() ->
    Mark = array_first([{bp_load_cases_decorator_expr_value@main@@Mark, <<"CITY">>, 2.5, <<"high">>, 1, 9, <<"name">>, [<<"a">>, <<"b">>]}]),
    case Mark of
        undefined -> undefined;
        M ->
            '__bp_print'([<<('__bp_text'(erlang:element(2, M)))/binary, " ", ('__bp_text'(float_to_binary(erlang:element(3, M), [short])))/binary, " ", ('__bp_text'(erlang:element(4, M)))/binary, " ", ('__bp_text'(erlang:integer_to_binary(erlang:element(5, M))))/binary, "..", ('__bp_text'(erlang:integer_to_binary(erlang:element(6, M))))/binary, " ", ('__bp_text'(erlang:element(7, M)))/binary, " ", ('__bp_text'(iolist_to_binary(lists:join(<<"+">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, erlang:element(8, M))))))/binary>>])
    end,
    '__bp_print'(['scale_$0'(7)]),
    '__bp_print'(['scale_$1'(2)]),
    '__bp_print'([<<"HELLO!">>]).

% What `#[mark]` records: each argument's value as the body read it.

%% type Mark: shown, weight, level, min, max, key, tags

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/decorator_expr_value|*">>.

'scale_$0'(X) ->
    N = 3,
    '__bp_int'((X * N), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:42:14">>).

'scale_$1'(X) ->
    N = 5,
    '__bp_int'((X * N), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:42:14">>).

array_first(Self) ->
    (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Self, 0).

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

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

'__bp_priv__array_first'(A0) -> array_first(A0).

-module(bp_load_cases_case_if_union_value_shapes@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__show'/1, '__bp_priv__blockArms'/1, '__bp_priv__lambdaArms'/1, '__bp_priv__unknownSubject'/1, '__bp_priv__pick'/1, '__bp_priv__argument'/1, '__bp_priv__ifValue'/1, '__bp_priv__ifReturn'/1, '__bp_priv__ifArgument'/1, '__bp_priv__later'/1, '__bp_priv__machine'/1, '__bp_priv__run'/0, '__bp_priv__pickBlock'/1, '__bp_priv__argumentBlock'/1, '__bp_priv__ifReturnBlock'/1, '__bp_priv__ifArgumentBlock'/1, '__bp_priv__ifPlainValue'/1]).

%%% Decision 150 (decision 8 §3.2) — a `case` whose arms disagree, and an

%%% `if` / `else` whose branches do, is the union of their types whatever

%%% shape an arm is written in (a value, a block, a lambda arm, over an

%%% `unknown` subject, inside an `async` body that awaits) and wherever the

%%% value goes (a `val`, a `return` from a function answering the union, an

%%% argument of a parameter of it): each value read back is the member it is.

%% type Shape
%%   Circle(r)
%%   Label(text)

show(V) ->
    case V of
        I32 when erlang:is_number(I32), (I32 == erlang:trunc(I32)), (I32 >= -2147483648), (I32 =< 2147483647) ->
            N = erlang:trunc(I32),
            <<"number ", ('__bp_text'(N))/binary>>;
        T = String when erlang:is_binary(String) ->
            <<"text ", ('__bp_text'(T))/binary>>
    end.

blockArms(S) ->
    V = case S of
        {bp_load_cases_case_if_union_value_shapes@main@@Shape__v__circle, R} ->
            D = '__bp_int'((R * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:29:23">>),
            D;
        {bp_load_cases_case_if_union_value_shapes@main@@Shape__v__label, Text} ->
            Text
    end,
    case V of
        I32 when erlang:is_number(I32), (I32 == erlang:trunc(I32)), (I32 >= -2147483648), (I32 =< 2147483647) ->
            N = erlang:trunc(I32),
            <<"number ", ('__bp_text'(N))/binary>>;
        T = String when erlang:is_binary(String) ->
            <<"text ", ('__bp_text'(T))/binary>>
    end.

lambdaArms(U) ->
    V = case U of
        I32 when erlang:is_number(I32), (I32 == erlang:trunc(I32)), (I32 >= -2147483648), (I32 =< 2147483647) ->
            N = erlang:trunc(I32),
            '__bp_int'((N * 3), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:49:15">>);
        T = String when erlang:is_binary(String) ->
            <<('__bp_text'(T))/binary, "!">>
    end,
    case V of
        I32@1 when erlang:is_number(I32@1), (I32@1 == erlang:trunc(I32@1)), (I32@1 >= -2147483648), (I32@1 =< 2147483647) ->
            N@1 = erlang:trunc(I32@1),
            <<"number ", ('__bp_text'(N@1))/binary>>;
        T@1 = String@1 when erlang:is_binary(String@1) ->
            <<"text ", ('__bp_text'(T@1))/binary>>
    end.

unknownSubject(U) ->
    V = case U of
        I32 when erlang:is_number(I32), (I32 == erlang:trunc(I32)), (I32 >= -2147483648), (I32 =< 2147483647) ->
            N = erlang:trunc(I32),
            '__bp_int'((N * 4), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:68:15">>);
        _ ->
            <<"other">>
    end,
    case V of
        I32@1 when erlang:is_number(I32@1), (I32@1 == erlang:trunc(I32@1)), (I32@1 >= -2147483648), (I32@1 =< 2147483647) ->
            N@1 = erlang:trunc(I32@1),
            <<"number ", ('__bp_text'(N@1))/binary>>;
        T = String when erlang:is_binary(String) ->
            <<"text ", ('__bp_text'(T))/binary>>
    end.

pick(S) ->
    case S of
        {bp_load_cases_case_if_union_value_shapes@main@@Shape__v__circle, R} ->
            '__bp_int'((R * 5), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:84:24">>);
        {bp_load_cases_case_if_union_value_shapes@main@@Shape__v__label, Text} ->
            Text
    end.

argument(S) ->
    show(case S of
        {bp_load_cases_case_if_union_value_shapes@main@@Shape__v__circle, R} ->
            '__bp_int'((R * 6), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:91:24">>);
        {bp_load_cases_case_if_union_value_shapes@main@@Shape__v__label, Text} ->
            Text
    end).

ifValue(B) ->
    V = case B of
        true ->
            D = 7,
            D;
        false ->
            T = <<"seven">>,
            T
    end,
    case V of
        I32 when erlang:is_number(I32), (I32 == erlang:trunc(I32)), (I32 >= -2147483648), (I32 =< 2147483647) ->
            N = erlang:trunc(I32),
            <<"number ", ('__bp_text'(N))/binary>>;
        T@1 = String when erlang:is_binary(String) ->
            <<"text ", T@1/binary>>
    end.

ifReturn(B) ->
    case B of
        true ->
            8;
        false ->
            <<"eight">>
    end.

ifArgument(B) ->
    show(case B of
        true ->
            9;
        false ->
            <<"nine">>
    end).

later(N) ->
    (fun() ->
        N
    end)().

machine(S) ->
    (fun() ->
        K = later(10),
        V = case S of
            {bp_load_cases_case_if_union_value_shapes@main@@Shape__v__circle, R} ->
                '__bp_int'((R * K), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:132:28">>);
            {bp_load_cases_case_if_union_value_shapes@main@@Shape__v__label, Text} ->
                Text
        end,
        case V of
            I32 when erlang:is_number(I32), (I32 == erlang:trunc(I32)), (I32 >= -2147483648), (I32 =< 2147483647) ->
                N = erlang:trunc(I32),
                <<"number ", ('__bp_text'(N))/binary>>;
            T = String when erlang:is_binary(String) ->
                <<"text ", ('__bp_text'(T))/binary>>
        end
    end)().

%% @Async — eager lowering
run() ->
    '__bp_print'([machine({bp_load_cases_case_if_union_value_shapes@main@@Shape__v__circle, 1})]),
    '__bp_print'([machine({bp_load_cases_case_if_union_value_shapes@main@@Shape__v__label, <<"m">>})]).

pickBlock(S) ->
    case S of
        {bp_load_cases_case_if_union_value_shapes@main@@Shape__v__circle, R} ->
            D = '__bp_int'((R * 11), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:154:23">>),
            D;
        {bp_load_cases_case_if_union_value_shapes@main@@Shape__v__label, Text} ->
            Text
    end.

argumentBlock(S) ->
    show(case S of
        {bp_load_cases_case_if_union_value_shapes@main@@Shape__v__circle, R} ->
            D = '__bp_int'((R * 12), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:166:23">>),
            D;
        {bp_load_cases_case_if_union_value_shapes@main@@Shape__v__label, Text} ->
            Text
    end).

ifReturnBlock(B) ->
    case B of
        true ->
            D = 13,
            D;
        false ->
            <<"thirteen">>
    end.

ifArgumentBlock(B) ->
    show(case B of
        true ->
            D = 14,
            D;
        false ->
            <<"fourteen">>
    end).

ifPlainValue(B) ->
    V = case B of
        true ->
            15;
        false ->
            <<"fifteen">>
    end,
    show(V).

main() ->
    '__bp_print'([blockArms({bp_load_cases_case_if_union_value_shapes@main@@Shape__v__circle, 1})]),
    '__bp_print'([blockArms({bp_load_cases_case_if_union_value_shapes@main@@Shape__v__label, <<"b">>})]),
    '__bp_print'([lambdaArms(1)]),
    '__bp_print'([lambdaArms(<<"l">>)]),
    '__bp_print'([unknownSubject(1)]),
    '__bp_print'([unknownSubject(<<"u">>)]),
    '__bp_print'([show(pick({bp_load_cases_case_if_union_value_shapes@main@@Shape__v__circle, 1}))]),
    '__bp_print'([show(pick({bp_load_cases_case_if_union_value_shapes@main@@Shape__v__label, <<"p">>}))]),
    '__bp_print'([argument({bp_load_cases_case_if_union_value_shapes@main@@Shape__v__circle, 1})]),
    '__bp_print'([argument({bp_load_cases_case_if_union_value_shapes@main@@Shape__v__label, <<"a">>})]),
    '__bp_print'([ifValue(true)]),
    '__bp_print'([ifValue(false)]),
    '__bp_print'([show(ifReturn(true))]),
    '__bp_print'([show(ifReturn(false))]),
    '__bp_print'([ifArgument(true)]),
    '__bp_print'([ifArgument(false)]),
    '__bp_print'([show(pickBlock({bp_load_cases_case_if_union_value_shapes@main@@Shape__v__circle, 1}))]),
    '__bp_print'([show(pickBlock({bp_load_cases_case_if_union_value_shapes@main@@Shape__v__label, <<"pb">>}))]),
    '__bp_print'([argumentBlock({bp_load_cases_case_if_union_value_shapes@main@@Shape__v__circle, 1})]),
    '__bp_print'([argumentBlock({bp_load_cases_case_if_union_value_shapes@main@@Shape__v__label, <<"ab">>})]),
    '__bp_print'([show(ifReturnBlock(true))]),
    '__bp_print'([show(ifReturnBlock(false))]),
    '__bp_print'([ifArgumentBlock(true)]),
    '__bp_print'([ifArgumentBlock(false)]),
    '__bp_print'([ifPlainValue(true)]),
    '__bp_print'([ifPlainValue(false)]),
    run().

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/case_if_union_value_shapes|*">>.

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

'__bp_priv__show'(A0) -> show(A0).

'__bp_priv__blockArms'(A0) -> blockArms(A0).

'__bp_priv__lambdaArms'(A0) -> lambdaArms(A0).

'__bp_priv__unknownSubject'(A0) -> unknownSubject(A0).

'__bp_priv__pick'(A0) -> pick(A0).

'__bp_priv__argument'(A0) -> argument(A0).

'__bp_priv__ifValue'(A0) -> ifValue(A0).

'__bp_priv__ifReturn'(A0) -> ifReturn(A0).

'__bp_priv__ifArgument'(A0) -> ifArgument(A0).

'__bp_priv__later'(A0) -> later(A0).

'__bp_priv__machine'(A0) -> machine(A0).

'__bp_priv__run'() -> run().

'__bp_priv__pickBlock'(A0) -> pickBlock(A0).

'__bp_priv__argumentBlock'(A0) -> argumentBlock(A0).

'__bp_priv__ifReturnBlock'(A0) -> ifReturnBlock(A0).

'__bp_priv__ifArgumentBlock'(A0) -> ifArgumentBlock(A0).

'__bp_priv__ifPlainValue'(A0) -> ifPlainValue(A0).

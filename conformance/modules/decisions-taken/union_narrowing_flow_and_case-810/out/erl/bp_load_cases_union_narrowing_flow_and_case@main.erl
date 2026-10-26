-module(bp_load_cases_union_narrowing_flow_and_case@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__area'/1, '__bp_priv__name'/1, '__bp_priv__viaLocals'/1, '__bp_priv__sides'/1, '__bp_priv__first'/1, '__bp_priv__firstCase'/1, '__bp_priv__describe'/1]).

%%% Decision 810 — a union narrows by the flow of an `is` and by an

%%% exhaustive `case` with type patterns, both in force. (2) Past an `if`

%%% whose branch leaves, the name is the union without the member it tested,

%%% each further test removing one more; in the `else` too; for a parameter,

%%% a `val`, a loop's binder and a `var` until it is assigned. (1) `v is

%%% Box<T>` is accepted where `Box<T>` is a member of `v`'s type, `T` bound

%%% through it. (3) A `case` over a union covers it with a type pattern per

%%% member, a generic one included (`Box<T> { b -> … }`), and needs no `_`.

%% type Dot: label

%% type Circle: r

%% type Square: side

%% type Box: item

%% type Pair: left, right

area(S) ->
    case ((erlang:is_tuple(S) andalso (erlang:tuple_size(S) =:= 2)) andalso (erlang:element(1, S) =:= bp_load_cases_union_narrowing_flow_and_case@main@@Dot)) of
        true ->
            0;
        _ ->
            case ((erlang:is_tuple(S) andalso (erlang:tuple_size(S) =:= 2)) andalso (erlang:element(1, S) =:= bp_load_cases_union_narrowing_flow_and_case@main@@Circle)) of
                true ->
                    '__bp_int'(('__bp_int'((erlang:element(2, S) * erlang:element(2, S)), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:24:33">>) * 3), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:24:39">>);
                _ ->
                    '__bp_int'((erlang:element(2, S) * erlang:element(2, S)), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:25:19">>)
            end
    end.

name(S) ->
    case ((erlang:is_tuple(S) andalso (erlang:tuple_size(S) =:= 2)) andalso (erlang:element(1, S) =:= bp_load_cases_union_narrowing_flow_and_case@main@@Dot)) of
        true ->
            erlang:element(2, S);
        false ->
            <<"circle ", ('__bp_text'(erlang:integer_to_binary(erlang:element(2, S))))/binary>>
    end.

viaLocals(S) ->
    V = S,
    case ((erlang:is_tuple(V) andalso (erlang:tuple_size(V) =:= 2)) andalso (erlang:element(1, V) =:= bp_load_cases_union_narrowing_flow_and_case@main@@Square)) of
        true ->
            <<"square">>;
        _ ->
            W = V,
            case ((erlang:is_tuple(W) andalso (erlang:tuple_size(W) =:= 2)) andalso (erlang:element(1, W) =:= bp_load_cases_union_narrowing_flow_and_case@main@@Dot)) of
                true ->
                    erlang:element(2, W);
                _ ->
                    R = erlang:element(2, W),
                    W@1 = {bp_load_cases_union_narrowing_flow_and_case@main@@Dot, <<"reset">>},
                    <<"r=", ('__bp_text'(erlang:integer_to_binary(R)))/binary>>
            end
    end.

sides(Shapes) ->
    Total = 0,
    Total@3 = (fun __BpLoop(__BpIter1, Total@1) ->
        case __BpIter1 of
            [S | __BpRest1] ->
                __BpLoop(__BpRest1, try
                    case ((erlang:is_tuple(S) andalso (erlang:tuple_size(S) =:= 2)) andalso (erlang:element(1, S) =:= bp_load_cases_union_narrowing_flow_and_case@main@@Dot)) of
                        true ->
                            erlang:throw({'__bp_cond_continue', Total@1});
                        _ -> ok
                    end,
                    Total@2 = '__bp_int'((Total@1 + erlang:element(2, S)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:46:23">>),
                    Total@2
                catch
                    throw:{'__bp_cond_continue', __BpGroup1} -> __BpGroup1
                end);
            _ -> Total@1
        end
    end)(Shapes, Total),
    Total@3.

first(V) ->
    case ((erlang:is_tuple(V) andalso (erlang:tuple_size(V) =:= 2)) andalso (erlang:element(1, V) =:= bp_load_cases_union_narrowing_flow_and_case@main@@Box)) of
        true ->
            erlang:element(2, V);
        _ ->
            erlang:element(2, V)
    end.

firstCase(V) ->
    case V of
        B = Box when ((erlang:is_tuple(Box) andalso (erlang:tuple_size(Box) =:= 2)) andalso (erlang:element(1, Box) =:= bp_load_cases_union_narrowing_flow_and_case@main@@Box)) ->
            erlang:element(2, B);
        P = Pair when ((erlang:is_tuple(Pair) andalso (erlang:tuple_size(Pair) =:= 3)) andalso (erlang:element(1, Pair) =:= bp_load_cases_union_narrowing_flow_and_case@main@@Pair)) ->
            erlang:element(2, P)
    end.

describe(S) ->
    case S of
        D = Dot when ((erlang:is_tuple(Dot) andalso (erlang:tuple_size(Dot) =:= 2)) andalso (erlang:element(1, Dot) =:= bp_load_cases_union_narrowing_flow_and_case@main@@Dot)) ->
            <<"dot ", ('__bp_text'(erlang:element(2, D)))/binary>>;
        C = Circle when ((erlang:is_tuple(Circle) andalso (erlang:tuple_size(Circle) =:= 2)) andalso (erlang:element(1, Circle) =:= bp_load_cases_union_narrowing_flow_and_case@main@@Circle)) ->
            <<"circle ", ('__bp_text'(erlang:integer_to_binary(erlang:element(2, C))))/binary>>;
        Q = Square when ((erlang:is_tuple(Square) andalso (erlang:tuple_size(Square) =:= 2)) andalso (erlang:element(1, Square) =:= bp_load_cases_union_narrowing_flow_and_case@main@@Square)) ->
            <<"square ", ('__bp_text'(erlang:integer_to_binary(erlang:element(2, Q))))/binary>>
    end.

main() ->
    '__bp_print'([area({bp_load_cases_union_narrowing_flow_and_case@main@@Dot, <<"d">>}), area({bp_load_cases_union_narrowing_flow_and_case@main@@Circle, 2}), area({bp_load_cases_union_narrowing_flow_and_case@main@@Square, 4})]),
    '__bp_print'([name({bp_load_cases_union_narrowing_flow_and_case@main@@Dot, <<"dot">>})]),
    '__bp_print'([name({bp_load_cases_union_narrowing_flow_and_case@main@@Circle, 5})]),
    '__bp_print'([viaLocals({bp_load_cases_union_narrowing_flow_and_case@main@@Square, 1}), viaLocals({bp_load_cases_union_narrowing_flow_and_case@main@@Dot, <<"kept">>}), viaLocals({bp_load_cases_union_narrowing_flow_and_case@main@@Circle, 7})]),
    '__bp_print'([sides([{bp_load_cases_union_narrowing_flow_and_case@main@@Dot, <<"a">>}, {bp_load_cases_union_narrowing_flow_and_case@main@@Square, 2}, {bp_load_cases_union_narrowing_flow_and_case@main@@Square, 3}])]),
    '__bp_print'([first({bp_load_cases_union_narrowing_flow_and_case@main@@Box, <<"boxed">>}), first({bp_load_cases_union_narrowing_flow_and_case@main@@Pair, <<"left">>, <<"right">>})]),
    '__bp_print'([firstCase({bp_load_cases_union_narrowing_flow_and_case@main@@Box, 1}), firstCase({bp_load_cases_union_narrowing_flow_and_case@main@@Pair, 2, 3})]),
    '__bp_print'([describe({bp_load_cases_union_narrowing_flow_and_case@main@@Dot, <<"x">>})]),
    '__bp_print'([describe({bp_load_cases_union_narrowing_flow_and_case@main@@Circle, 1})]),
    '__bp_print'([describe({bp_load_cases_union_narrowing_flow_and_case@main@@Square, 9})]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/union_narrowing_flow_and_case|*">>.

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

'__bp_priv__area'(A0) -> area(A0).

'__bp_priv__name'(A0) -> name(A0).

'__bp_priv__viaLocals'(A0) -> viaLocals(A0).

'__bp_priv__sides'(A0) -> sides(A0).

'__bp_priv__first'(A0) -> first(A0).

'__bp_priv__firstCase'(A0) -> firstCase(A0).

'__bp_priv__describe'(A0) -> describe(A0).

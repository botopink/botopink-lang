----- SOURCE CODE -- main.bp
```botopink
pub fn main() -> void {
    val xs = [3, 1, 3, 2, 1];
    print(xs.unique());
    print(["a", "b", "a"].unique());
    print([[1, 2], [3]].flatten());
    print(xs.chunked(2));
    print(xs.sliding(3));
    print(xs.map({ x -> x * 2 }));
    print(xs.filter({ x -> x > 1 }));
    print(xs.fold(0, { acc, x -> acc + x }));
    print(xs.any({ x -> x == 2 }), xs.all({ x -> x > 0 }), xs.count({ x -> x == 3 }));
    print(["a", "bb"].map({ s -> s.length() }));
    print(xs.zip(["a", "b"]));
}

import {io.terminal.print} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__array_unique'/1, '__bp_priv__array_flatten'/1, '__bp_priv__array_chunked'/2, '__bp_priv__array_sliding'/2, '__bp_priv__array_any'/2, '__bp_priv__array_all'/2, '__bp_priv__array_count'/2, '__bp_priv__array_slice'/3]).

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

main() ->
    Xs = [3, 1, 3, 2, 1],
    '__bp_print'([array_unique(Xs)]),
    '__bp_print'([array_unique([<<"a">>, <<"b">>, <<"a">>])]),
    '__bp_print'([array_flatten([[1, 2], [3]])]),
    '__bp_print'([array_chunked(Xs, 2)]),
    '__bp_print'([array_sliding(Xs, 3)]),
    '__bp_print'([lists:map(fun(X) ->
        '__bp_int'((X * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:8:27">>)
    end, Xs)]),
    '__bp_print'([lists:filter(fun(X) ->
        (X > 1)
    end, Xs)]),
    '__bp_print'([lists:foldl(fun(__X, __A) -> (fun(Acc, X) ->
        '__bp_add'(Acc, X)
    end)(__A, __X) end, 0, Xs)]),
    '__bp_print'([array_any(Xs, fun(X) ->
        (X =:= 2)
    end), array_all(Xs, fun(X) ->
        (X > 0)
    end), array_count(Xs, fun(X) ->
        (X =:= 3)
    end)]),
    '__bp_print'([lists:map(fun(S) ->
        erlang:length(unicode:characters_to_list(S))
    end, [<<"a">>, <<"bb">>])]),
    '__bp_print'([lists:zipwith(fun(__X, __Y) -> {__X, __Y} end, lists:sublist(Xs, length([<<"a">>, <<"b">>])), lists:sublist([<<"a">>, <<"b">>], length(Xs)))]).

array_unique(Self) ->
    Out = lists:foldl(fun(X, Out) ->
        case (not '__bp_prim_any'(Out, fun(Y) ->
            (Y =:= X)
        end)) of
            true -> '__bp_prim_append'(Out, [X]);
            _ -> Out
        end
    end, [], Self),
    Out.

array_flatten(Self) ->
    Out = lists:foldl(fun(Inner, Out) ->
        '__bp_prim_append'(Out, Inner)
    end, [], Self),
    Out.

array_chunked(Self, N) ->
    Out = [],
    case (N =< 0) of
        true ->
            Out;
        _ ->
            Len = erlang:length(Self),
            Out@4 = lists:foldl(fun(K, Out@1) ->
                Out@3 = case ((K rem N) =:= 0) of
                    true ->
                        Out@2 = (Out@1 ++ [array_slice(Self, K, (K + N))]),
                        Out@2;
                    _ ->
                        Out@1
                end,
                Out@3
            end, Out, lists:seq(0, (Len) - 1)),
            Out@4
    end.

array_sliding(Self, N) ->
    Out = [],
    case (N =< 0) of
        true ->
            Out;
        _ ->
            Windows = ((erlang:length(Self) - N) + 1),
            case (Windows =< 0) of
                true ->
                    Out;
                _ ->
                    Out@3 = lists:foldl(fun(K, Out@1) ->
                        Out@2 = (Out@1 ++ [array_slice(Self, K, (K + N))]),
                        Out@2
                    end, Out, lists:seq(0, (Windows) - 1)),
                    Out@3
            end
    end.

array_any(Self, Pred) ->
    (erlang:length(lists:filter(Pred, Self)) =/= 0).

array_all(Self, Pred) ->
    (erlang:length(lists:filter(Pred, Self)) =:= erlang:length(Self)).

array_count(Self, Pred) ->
    erlang:length(lists:filter(Pred, Self)).

array_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            lists:sublist(Self, (Start) + 1, ((End) - (Start)));
        false ->
            lists:nthtail(Start, Self)
    end.

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

'__bp_prim_any'(Recv, Arg0) when erlang:is_list(Recv) ->
    array_any(Recv, Arg0);
'__bp_prim_any'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"any">>, 1, Recv}).

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
'__bp_show'(V, _) when erlang:is_function(V) -> ["fn/", erlang:integer_to_list(erlang:element(2, erlang:fun_info(V, arity)))];
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

'__bp_priv__array_unique'(A0) -> array_unique(A0).

'__bp_priv__array_flatten'(A0) -> array_flatten(A0).

'__bp_priv__array_chunked'(A0, A1) -> array_chunked(A0, A1).

'__bp_priv__array_sliding'(A0, A1) -> array_sliding(A0, A1).

'__bp_priv__array_any'(A0, A1) -> array_any(A0, A1).

'__bp_priv__array_all'(A0, A1) -> array_all(A0, A1).

'__bp_priv__array_count'(A0, A1) -> array_count(A0, A1).

'__bp_priv__array_slice'(A0, A1, A2) -> array_slice(A0, A1, A2).
```

----- RUN LOG -----
```logs
[3, 1, 2]
["a", "b"]
[1, 2, 3]
[[3, 1], [3, 2], [1]]
[[3, 1, 3], [1, 3, 2], [3, 2, 1]]
[6, 2, 6, 4, 2]
[3, 3, 2]
10
true true 2
[1, 2]
[#(3, "a"), #(1, "b")]
```

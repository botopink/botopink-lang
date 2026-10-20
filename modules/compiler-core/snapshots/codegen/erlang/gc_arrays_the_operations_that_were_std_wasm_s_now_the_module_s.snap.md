----- SOURCE CODE -- main.bp
```botopink
pub fn main() -> void {
    val xs = [3, 1, 2];
    print(xs.reverse());
    print(xs.slice(1));
    print(xs.slice(0, 2));
    print(xs.take(2));
    print(xs.drop(1));
    print(xs.rest());
    print(xs.append([9, 8]));
    print(xs.prepend(7));
    print(xs.indexOf(2));
    print(xs.indexOf(5));
    print(xs.lastIndexOf(1));
    print(xs.contains(1));
    print(xs.contains(8));
    print(xs.join("-"));
    val ws = ["a", "b", "c"];
    print(ws.reverse());
    print(ws.join(", "));
    print(ws.indexOf("c"));
    print(ws.contains("z"));
    val ns = [-5, 0, 123];
    print(ns.join("|"));
    val fs = [1.5, 2.5];
    print(fs.reverse());
    print(fs.indexOf(2.5));
}

import {io.terminal.print} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__array_slice'/3, '__bp_priv__array_rest'/1]).

%% behavior Array

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
    Xs = [3, 1, 2],
    '__bp_print'([lists:reverse(Xs)]),
    '__bp_print'([array_slice(Xs, 1, undefined)]),
    '__bp_print'([array_slice(Xs, 0, 2)]),
    '__bp_print'([lists:sublist(Xs, 2)]),
    '__bp_print'([lists:nthtail(1, Xs)]),
    '__bp_print'([array_rest(Xs)]),
    '__bp_print'([(Xs ++ [9, 8])]),
    '__bp_print'([[7 | Xs]]),
    '__bp_print'([(fun(__L, __X) -> __Find = fun __F(__I, [__H | __T]) -> case (__H =:= __X) of true -> __I; false -> __F(__I + 1, __T) end; __F(_, []) -> -1 end, __Find(0, __L) end)(Xs, 2)]),
    '__bp_print'([(fun(__L, __X) -> __Find = fun __F(__I, [__H | __T]) -> case (__H =:= __X) of true -> __I; false -> __F(__I + 1, __T) end; __F(_, []) -> -1 end, __Find(0, __L) end)(Xs, 5)]),
    '__bp_print'([(fun(__L, __X) -> __Find = fun __F(__I, [__H | __T], __Last) -> __F(__I + 1, __T, case (__H =:= __X) of true -> __I; false -> __Last end); __F(_, [], __Last) -> __Last end, __Find(0, __L, -1) end)(Xs, 1)]),
    '__bp_print'([lists:member(1, Xs)]),
    '__bp_print'([lists:member(8, Xs)]),
    '__bp_print'([iolist_to_binary(lists:join(<<"-">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Xs)))]),
    Ws = [<<"a">>, <<"b">>, <<"c">>],
    '__bp_print'([lists:reverse(Ws)]),
    '__bp_print'([iolist_to_binary(lists:join(<<", ">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Ws)))]),
    '__bp_print'([(fun(__L, __X) -> __Find = fun __F(__I, [__H | __T]) -> case (__H =:= __X) of true -> __I; false -> __F(__I + 1, __T) end; __F(_, []) -> -1 end, __Find(0, __L) end)(Ws, <<"c">>)]),
    '__bp_print'([lists:member(<<"z">>, Ws)]),
    Ns = [(-5), 0, 123],
    '__bp_print'([iolist_to_binary(lists:join(<<"|">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Ns)))]),
    Fs = [1.5, 2.5],
    '__bp_print'([lists:reverse(Fs)]),
    '__bp_print'([(fun(__L, __X) -> __Find = fun __F(__I, [__H | __T]) -> case (__H =:= __X) of true -> __I; false -> __F(__I + 1, __T) end; __F(_, []) -> -1 end, __Find(0, __L) end)(Fs, 2.5)]).

array_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            lists:sublist(Self, (Start) + 1, ((End) - (Start)));
        false ->
            lists:nthtail(Start, Self)
    end.

array_rest(Self) ->
    array_slice(Self, 1, erlang:length(Self)).

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

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

'__bp_priv__array_slice'(A0, A1, A2) -> array_slice(A0, A1, A2).

'__bp_priv__array_rest'(A0) -> array_rest(A0).
```

----- RUN LOG -----
```logs
[2, 1, 3]
[1, 2]
[3, 1]
[3, 1]
[1, 2]
[1, 2]
[3, 1, 2, 9, 8]
[7, 3, 1, 2]
2
-1
1
true
false
3-1-2
["c", "b", "a"]
a, b, c
2
false
-5|0|123
[2.5, 1.5]
1
```

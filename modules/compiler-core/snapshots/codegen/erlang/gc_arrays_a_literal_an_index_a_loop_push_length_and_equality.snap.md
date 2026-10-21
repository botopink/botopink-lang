----- SOURCE CODE -- main.bp
```botopink
fn total(xs: i32[]) -> i32 {
    var sum = 0;
    for (xs) { x -> sum = sum + x; }
    return sum;
}

fn longest(names: string[]) -> i32 {
    var best = 0;
    for (names) { n -> if (n.length() > best) { best = n.length(); } }
    return best;
}

pub fn main() -> void {
    val xs = [3, 1, 2];
    print(xs);
    print(total(xs));
    print(xs[1]);
    print(xs.length);
    print(xs.length());
    var ys = [10, 20];
    ys.push(30);
    print(ys);
    val names = ["ann", "bobby"];
    print(names);
    print(longest(names));
    print(names[1]);
    val fs = [1.5, 2.5];
    print(fs);
    print(xs == [3, 1, 2]);
    print(xs == ys);
    val e: i32[] = [];
    print(e.length());
    print(e);
}

import {io.terminal.print} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__total'/1, '__bp_priv__longest'/1]).

total(Xs) ->
    Sum = 0,
    Sum@3 = lists:foldl(fun(X, Sum@1) ->
        Sum@2 = '__bp_int'((Sum@1 + X), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:3:31">>),
        Sum@2
    end, Sum, Xs),
    Sum@3.

longest(Names) ->
    Best = 0,
    Best@4 = lists:foldl(fun(N, Best@1) ->
        Best@3 = case (erlang:length(unicode:characters_to_list(N)) > Best@1) of
            true ->
                Best@2 = erlang:length(unicode:characters_to_list(N)),
                Best@2;
            _ ->
                Best@1
        end,
        Best@3
    end, Best, Names),
    Best@4.

main() ->
    Xs = [3, 1, 2],
    '__bp_print'([Xs]),
    '__bp_print'([total(Xs)]),
    '__bp_print'([(fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Xs, 1)]),
    '__bp_print'([erlang:length(Xs)]),
    '__bp_print'([erlang:length(Xs)]),
    Ys = [10, 20],
    Ys@1 = (Ys ++ [30]),
    '__bp_print'([Ys@1]),
    Names = [<<"ann">>, <<"bobby">>],
    '__bp_print'([Names]),
    '__bp_print'([longest(Names)]),
    '__bp_print'([(fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Names, 1)]),
    Fs = [1.5, 2.5],
    '__bp_print'([Fs]),
    '__bp_print'([(Xs =:= [3, 1, 2])]),
    '__bp_print'([(Xs =:= Ys@1)]),
    E = [],
    '__bp_print'([erlang:length(E)]),
    '__bp_print'([E]).

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

'__bp_priv__total'(A0) -> total(A0).

'__bp_priv__longest'(A0) -> longest(A0).
```

----- RUN LOG -----
```logs
[3, 1, 2]
6
1
3
3
[10, 20, 30]
["ann", "bobby"]
5
bobby
[1.5, 2.5]
true
false
0
[]
```

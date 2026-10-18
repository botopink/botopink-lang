----- SOURCE CODE -- main.bp
```botopink
type Box(n: ?i32, s: ?string)

fn first(xs: i32[]) -> ?i32 {
    return xs.at(0);
}

fn pick(flag: bool) -> ?i32 {
    if (flag) {
        return 5;
    }
    return null;
}

fn show(o: ?i32) -> i32 {
    return o ?? -1;
}

pub fn main() {
    val xs = [7, 8];
    print(xs.at(1));
    print(xs.at(5));
    print(first(xs));
    print(pick(true));
    print(pick(false));
    print(show(pick(true)));
    print(show(pick(false)));
    val b = Box(n: 3, s: "x");
    print(b);
    val c = Box(n: null, s: null);
    print(c);
    if (b.n) { v -> print(v + 1); }
    val words = ["a", "b"];
    print(words.at(0));
    print(words.at(9));
    print(words[1] ?? "z");
    print(xs[0]);
    print(b.n == null);
    print(c.n == null);
}

import {io.terminal.print} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__first'/1, '__bp_priv__pick'/1, '__bp_priv__show'/1]).

%% type Box: n, s

first(Xs) ->
    (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Xs, 0).

pick(Flag) ->
    case Flag of
        true ->
            5;
        _ ->
            undefined
    end.

show(O) ->
    case O of
        undefined ->
            (-1);
        __bp_nullish ->
            __bp_nullish
    end.

main() ->
    Xs = [7, 8],
    '__bp_print'([(fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Xs, 1)]),
    '__bp_print'([(fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Xs, 5)]),
    '__bp_print'([first(Xs)]),
    '__bp_print'([pick(true)]),
    '__bp_print'([pick(false)]),
    '__bp_print'([show(pick(true))]),
    '__bp_print'([show(pick(false))]),
    B = {test@main@@Box, 3, <<"x">>},
    '__bp_print'([B]),
    C = {test@main@@Box, undefined, undefined},
    '__bp_print'([C]),
    case erlang:element(2, B) of
        undefined -> undefined;
        V ->
            '__bp_print'(['__bp_int'((V + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:31:29">>)])
    end,
    Words = [<<"a">>, <<"b">>],
    '__bp_print'([(fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Words, 0)]),
    '__bp_print'([(fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Words, 9)]),
    '__bp_print'([case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Words, 1) of
        undefined ->
            <<"z">>;
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([(fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Xs, 0)]),
    '__bp_print'([(erlang:element(2, B) =:= undefined)]),
    '__bp_print'([(erlang:element(2, C) =:= undefined)]).

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

'__bp_priv__first'(A0) -> first(A0).

'__bp_priv__pick'(A0) -> pick(A0).

'__bp_priv__show'(A0) -> show(A0).
```

----- ERLANG -- test@main@@Box.erl
```erlang
-module(test@main@@Box).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, n) -> erlang:element(2, V);
'__bp_get'(V, s) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Box", [{"n", erlang:element(2, V)}, {"s", erlang:element(3, V)}]}.
```

----- RUN LOG -----
```logs
8
null
7
5
null
5
-1
Box(n: 3, s: "x")
Box(n: null, s: null)
4
a
null
b
7
false
true
```

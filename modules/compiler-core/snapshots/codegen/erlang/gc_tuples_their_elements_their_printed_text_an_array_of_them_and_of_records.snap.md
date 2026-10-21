----- SOURCE CODE -- main.bp
```botopink
type Pair(a: i32, b: string)

pub fn main() -> void {
    val t = #(1, "x", 2.5, true);
    print(t);
    print(t.0);
    print(t.1);
    print(t._2);
    print(t._3);
    val u = #(1, "x", 2.5, true);
    print(t == u);
    val rs = [Pair(a: 1, b: "p"), Pair(a: 2, b: "q")];
    print(rs);
    for r in rs { print(r.b); }
    val ts = [#(1, "a"), #(2, "b")];
    print(ts);
    print(ts[0]);
}

import {io.terminal.print} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0]).

%% type Pair: a, b

main() ->
    T = {1, <<"x">>, 2.5, true},
    '__bp_print'([T]),
    '__bp_print'([erlang:element(1, T)]),
    '__bp_print'([erlang:element(2, T)]),
    '__bp_print'([erlang:element(3, T)]),
    '__bp_print'([erlang:element(4, T)]),
    U = {1, <<"x">>, 2.5, true},
    '__bp_print'([(T =:= U)]),
    Rs = [{test@main@@Pair, 1, <<"p">>}, {test@main@@Pair, 2, <<"q">>}],
    '__bp_print'([Rs]),
    lists:foreach(fun(R) ->
        '__bp_print'([erlang:element(3, R)])
    end, Rs),
    Ts = [{1, <<"a">>}, {2, <<"b">>}],
    '__bp_print'([Ts]),
    '__bp_print'([(fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Ts, 0)]).

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
```

----- ERLANG -- test@main@@Pair.erl
```erlang
-module(test@main@@Pair).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, a) -> erlang:element(2, V);
'__bp_get'(V, b) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Pair", [{"a", erlang:element(2, V)}, {"b", erlang:element(3, V)}]}.
```

----- RUN LOG -----
```logs
#(1, "x", 2.5, true)
1
x
2.5
true
true
[Pair(a: 1, b: "p"), Pair(a: 2, b: "q")]
p
q
[#(1, "a"), #(2, "b")]
#(1, "a")
```

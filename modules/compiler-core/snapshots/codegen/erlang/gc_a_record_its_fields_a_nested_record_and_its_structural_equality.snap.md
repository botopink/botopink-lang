----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
type Person(name: string, age: i32, tall: bool, h: f64, home: Point)

fn sum(p: Point) -> i32 {
    return p.x + p.y;
}

fn greet(p: Person) -> string {
    return "hi " + p.name;
}

pub fn main() {
    val p = Point(x: 1, y: 2);
    print(sum(p));
    print(p);
    val q = Person(name: "Ana", age: 30, tall: true, h: 1.75, home: p);
    print(greet(q));
    print(q);
    print(q.home.y);
    print(q.h);
    print(q.tall);
    print(p == Point(x: 1, y: 2));
    print(p == Point(x: 1, y: 3));
}

import {io.terminal.print} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__sum'/1, '__bp_priv__greet'/1]).

%% type Point: x, y

%% type Person: name, age, tall, h, home

sum(P) ->
    '__bp_add'(erlang:element(2, P), erlang:element(3, P)).

greet(P) ->
    <<"hi ", ('__bp_text'(erlang:element(2, P)))/binary>>.

main() ->
    P = {test@main@@Point, 1, 2},
    '__bp_print'([sum(P)]),
    '__bp_print'([P]),
    Q = {test@main@@Person, <<"Ana">>, 30, true, 1.75, P},
    '__bp_print'([greet(Q)]),
    '__bp_print'([Q]),
    '__bp_print'([erlang:element(3, erlang:element(6, Q))]),
    '__bp_print'([erlang:element(5, Q)]),
    '__bp_print'([erlang:element(4, Q)]),
    '__bp_print'([(P =:= {test@main@@Point, 1, 2})]),
    '__bp_print'([(P =:= {test@main@@Point, 1, 3})]).

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

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

'__bp_priv__sum'(A0) -> sum(A0).

'__bp_priv__greet'(A0) -> greet(A0).
```

----- ERLANG -- test@main@@Point.erl
```erlang
-module(test@main@@Point).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, x) -> erlang:element(2, V);
'__bp_get'(V, y) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Point", [{"x", erlang:element(2, V)}, {"y", erlang:element(3, V)}]}.
```

----- ERLANG -- test@main@@Person.erl
```erlang
-module(test@main@@Person).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, age) -> erlang:element(3, V);
'__bp_get'(V, tall) -> erlang:element(4, V);
'__bp_get'(V, h) -> erlang:element(5, V);
'__bp_get'(V, home) -> erlang:element(6, V).

'__bp_format'(V) -> {record, "Person", [{"name", erlang:element(2, V)}, {"age", erlang:element(3, V)}, {"tall", erlang:element(4, V)}, {"h", erlang:element(5, V)}, {"home", erlang:element(6, V)}]}.
```

----- RUN LOG -----
```logs
3
Point(x: 1, y: 2)
hi Ana
Person(name: "Ana", age: 30, tall: true, h: 1.75, home: Point(x: 1, y: 2))
2
1.75
true
true
false
```

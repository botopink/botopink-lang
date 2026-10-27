----- SOURCE CODE -- main.bp
```botopink
type Shape {
    Circle(r: i32),
    Rect(w: i32, h: i32),
    Dot,
}

fn area(s: Shape) -> i32 {
    return case s {
        Circle(r) -> r * r * 3;
        Rect(w, h) -> w * h;
        Dot -> 0;
    };
}

fn name(s: Shape) -> string {
    return case s {
        Circle -> "circle";
        Rect -> "rect";
        Dot -> "dot";
    };
}

pub fn main() -> void {
    val a = Shape.Circle(r: 2);
    val b = Shape.Rect(w: 3, h: 4);
    print(area(a));
    print(area(b));
    print(area(Shape.Dot));
    print(name(b));
    print(a);
    print(b);
    print(Shape.Dot);
    print(a == Shape.Circle(r: 2));
    print(a == b);
}

import {io.terminal.print} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__area'/1, '__bp_priv__name'/1]).

%% type Shape
%%   Circle(r)
%%   Rect(w, h)
%%   Dot

area(S) ->
    case S of
        {test@main@@Shape__v__circle, R} ->
            '__bp_int'(('__bp_int'((R * R), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:9:24">>) * 3), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:9:28">>);
        {test@main@@Shape__v__rect, W, H} ->
            '__bp_int'((W * H), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:10:25">>);
        test@main@@Shape__v__dot ->
            0
    end.

name(S) ->
    case S of
        test@main@@Shape__v__circle ->
            <<"circle">>;
        test@main@@Shape__v__rect ->
            <<"rect">>;
        test@main@@Shape__v__dot ->
            <<"dot">>
    end.

main() ->
    A = {test@main@@Shape__v__circle, 2},
    B = {test@main@@Shape__v__rect, 3, 4},
    '__bp_print'([area(A)]),
    '__bp_print'([area(B)]),
    '__bp_print'([area(test@main@@Shape__v__dot)]),
    '__bp_print'([name(B)]),
    '__bp_print'([A]),
    '__bp_print'([B]),
    '__bp_print'([test@main@@Shape__v__dot]),
    '__bp_print'([(A =:= {test@main@@Shape__v__circle, 2})]),
    '__bp_print'([(A =:= B)]).

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

'__bp_priv__area'(A0) -> area(A0).

'__bp_priv__name'(A0) -> name(A0).
```

----- ERLANG -- test@main@@Shape.erl
```erlang
-module(test@main@@Shape).
-export(['__bp_format'/1]).

'__bp_format'({test@main@@Shape__v__circle, F0}) -> {variant, "Shape.Circle", [{"r", F0}]};
'__bp_format'({test@main@@Shape__v__rect, F0, F1}) -> {variant, "Shape.Rect", [{"w", F0}, {"h", F1}]};
'__bp_format'(test@main@@Shape__v__dot) -> {variant, "Shape.Dot", []}.
```

----- RUN LOG -----
```logs
```

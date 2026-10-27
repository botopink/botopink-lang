----- SOURCE CODE -- main.bp
```botopink
type Shape {
    Circle(radius: f64),
    Square(side: f64),
}

type Color { Red, Green, Blue }

type Item(shape: Shape, color: Color, label: string)

fn area(shape: Shape) -> f64 {
    return case shape {
        Circle(radius) -> radius * radius * 3.14;
        Square(side) -> side * side;
    };
}

fn warm(c: Color) -> bool {
    return case c {
        Red -> true;
        Green -> false;
        Blue -> false;
    };
}

pub fn main() -> void {
    print(area(Shape.Square(side: 2.0)));
    print(area(Shape.Circle(radius: 1.0)));
    val it = Item(shape: Shape.Square(side: 3.0), color: Color.Green, label: "x");
    print(it);
    print(warm(it.color));
    print(it.color);
    print(area(it.shape));
}

import {io.terminal.print} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__area'/1, '__bp_priv__warm'/1]).

%% type Shape
%%   Circle(radius)
%%   Square(side)

%% type Color
%%   Red
%%   Green
%%   Blue

%% type Item: shape, color, label

area(Shape) ->
    case Shape of
        {test@main@@Shape__v__circle, Radius} ->
            ((Radius * Radius) * 3.14);
        {test@main@@Shape__v__square, Side} ->
            (Side * Side)
    end.

warm(C) ->
    case C of
        test@main@@Color__v__red ->
            true;
        test@main@@Color__v__green ->
            false;
        test@main@@Color__v__blue ->
            false
    end.

main() ->
    '__bp_print'([area({test@main@@Shape__v__square, 2.0})]),
    '__bp_print'([area({test@main@@Shape__v__circle, 1.0})]),
    It = {test@main@@Item, {test@main@@Shape__v__square, 3.0}, test@main@@Color__v__green, <<"x">>},
    '__bp_print'([It]),
    '__bp_print'([warm(erlang:element(3, It))]),
    '__bp_print'([erlang:element(3, It)]),
    '__bp_print'([area(erlang:element(2, It))]).

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

'__bp_priv__warm'(A0) -> warm(A0).
```

----- ERLANG -- test@main@@Shape.erl
```erlang
-module(test@main@@Shape).
-export(['__bp_format'/1]).

'__bp_format'({test@main@@Shape__v__circle, F0}) -> {variant, "Shape.Circle", [{"radius", F0}]};
'__bp_format'({test@main@@Shape__v__square, F0}) -> {variant, "Shape.Square", [{"side", F0}]}.
```

----- ERLANG -- test@main@@Color.erl
```erlang
-module(test@main@@Color).
-export(['__bp_format'/1]).

'__bp_format'(test@main@@Color__v__red) -> {variant, "Color.Red", []};
'__bp_format'(test@main@@Color__v__green) -> {variant, "Color.Green", []};
'__bp_format'(test@main@@Color__v__blue) -> {variant, "Color.Blue", []}.
```

----- ERLANG -- test@main@@Item.erl
```erlang
-module(test@main@@Item).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, shape) -> erlang:element(2, V);
'__bp_get'(V, color) -> erlang:element(3, V);
'__bp_get'(V, label) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Item", [{"shape", erlang:element(2, V)}, {"color", erlang:element(3, V)}, {"label", erlang:element(4, V)}]}.
```

----- RUN LOG -----
```logs
4.0
3.14
Item(shape: Shape.Square(side: 3.0), color: Color.Green, label: "x")
false
Color.Green
9.0
```

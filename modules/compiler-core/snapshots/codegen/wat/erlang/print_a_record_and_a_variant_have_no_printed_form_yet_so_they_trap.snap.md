----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
type Shape { Square(side: i32), Nothing }
fn main() {
    @print("hi");
    @print([1, 2]);
    @print(#(1, "a"));
    @print(Point(x: 1, y: 2));
    @print(Shape.Square(side: 4));
    @print(Shape.Nothing);
    @print([Point(x: 1, y: 2)]);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

%% type Point: x, y

%% type Shape
%%   Square(side)
%%   Nothing

main() ->
    '__bp_print'([<<"hi">>]),
    '__bp_print'([[1, 2]]),
    '__bp_print'([{1, <<"a">>}]),
    '__bp_print'([{test@main@@Point, 1, 2}]),
    '__bp_print'([{test@main@@Shape__v__square, 4}]),
    '__bp_print'([test@main@@Shape__v__nothing]),
    '__bp_print'([[{test@main@@Point, 1, 2}]]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> '__bp_tagged'(element(1, V), V);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(atom_to_list(A), "__v__") of [P, _] -> list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- ERLANG -- test@main@@Point.erl
```erlang
-module(test@main@@Point).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, x) -> element(2, V);
'__bp_get'(V, y) -> element(3, V).

'__bp_format'(V) -> {record, "Point", [{"x", element(2, V)}, {"y", element(3, V)}]}.
```

----- ERLANG -- test@main@@Shape.erl
```erlang
-module(test@main@@Shape).
-export(['__bp_format'/1]).

'__bp_format'({test@main@@Shape__v__square, F0}) -> {variant, "Shape.Square", [{"side", F0}]};
'__bp_format'(test@main@@Shape__v__nothing) -> {variant, "Shape.Nothing", []}.
```

----- RUN LOG -----
```logs
hi
[1, 2]
#(1, "a")
Point(x: 1, y: 2)
Shape.Square(side: 4)
Shape.Nothing
[Point(x: 1, y: 2)]
```

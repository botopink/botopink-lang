----- SOURCE CODE -- main.bp
```botopink
type Shape { Circle(radius: f64), Square(side: f64) }
fn area(s: Shape) -> f64 {
    return case s {
        Circle(r) -> 3.14 * r * r;
        Square(s) -> s * s;
    };
}
fn main() {
    @print(area(Shape.Circle(2.0)));
    @print(area(Shape.Square(3.0)));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% type Shape
%%   Circle(radius)
%%   Square(side)

area(S) ->
    case S of
        {'Circle', R} ->
            ((3.14 * R) * R);
        {'Square', S@1} ->
            (S@1 * S@1)
    end.

main() ->
    '__bp_print'([area({'Circle', 2.0})]),
    '__bp_print'([area({'Square', 3.0})]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(",", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> io_lib:format("~p", [V]);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(",", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
12.56
9.0
```

----- SOURCE CODE -- main.bp
```botopink
type Shape {
    Circle(radius: i32),
    Rect(width: i32, height: i32),
}
fn main() {
    val c = Shape.Circle(radius: 7);
    case c {
        Shape.Circle(r) { @print(r); }
        _ { @print(0); }
    };
    val q = Shape.Rect(width: 2, height: 5);
    case q {
        Shape.Circle(r) { @print(r); }
        _ { @print(0); }
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% type Shape
%%   Circle(radius)
%%   Rect(width, height)

main() ->
    C = {'Circle', 7},
    case C of
        {'Circle', R} ->
            '__bp_print'([R]);
        _ ->
            '__bp_print'([0])
    end,
    Q = {'Rect', 2, 5},
    case Q of
        {'Circle', R@1} ->
            '__bp_print'([R@1]);
        _ ->
            '__bp_print'([0])
    end.

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
7
0
```

----- SOURCE CODE -- main.bp
```botopink
type Shape {
    Circle(radius: i32),
    Rect(width: i32, height: i32),
}
fn main() {
    val s = Shape.Circle(radius: 3);
    case s {
        Circle(r) { @print("circle"); }
        Rect(w, h) { @print("rect"); }
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
    S = {'Circle', 3},
    case S of
        {'Circle', R} ->
            '__bp_print'([<<"circle">>]);
        {'Rect', W, H} ->
            '__bp_print'([<<"rect">>])
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
circle
```

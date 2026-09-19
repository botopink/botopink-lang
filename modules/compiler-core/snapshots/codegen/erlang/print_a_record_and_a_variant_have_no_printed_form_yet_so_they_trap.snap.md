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
-module(main).
-export(['_botopink_main'/0, main/1]).

%% type Point: x, y

%% type Shape
%%   Square(side)
%%   Nothing

main() ->
    '__bp_print'([<<"hi">>]),
    '__bp_print'([[1, 2]]),
    '__bp_print'([{1, <<"a">>}]),
    '__bp_print'([#{x => 1, y => 2}]),
    '__bp_print'([{'Square', 4}]),
    '__bp_print'(['Nothing']),
    '__bp_print'([[#{x => 1, y => 2}]]).

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
hi
[1,2]
#(1,"a")
#{x => 1,y => 2}
{'Square',4}
'Nothing'
[#{x => 1,y => 2}]
```

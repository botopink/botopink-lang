----- SOURCE CODE -- main.bp
```botopink
enum Shape { Circle(radius: f64), Square(side: f64) }
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

%% enum Shape
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
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

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

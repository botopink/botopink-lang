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
        {tag, Circle, R} ->
            ((3.14 * R) * R);
        {tag, Square, S} ->
            (S * S)
    end.

main() ->
    io:format("~p~n", [area({'Circle', 2.0})]),
    io:format("~p~n", [area({'Square', 3.0})]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

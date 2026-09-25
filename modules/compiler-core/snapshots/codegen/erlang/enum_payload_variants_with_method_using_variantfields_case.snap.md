----- SOURCE CODE -- main.bp
```botopink
val Shape = type {
    Circle(radius: f64),
    Square(side: f64),
    Triangle(base: f64, height: f64),
    fn area(shape: Self) -> f64 {
        return case shape {
            Circle(radius) -> radius * radius * 3.14;
            Square(side) -> side * side;
            Triangle(base, height) -> base * height * 0.5;
            _ -> 0.0;
        };
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Shape
%%   Circle(radius)
%%   Square(side)
%%   Triangle(base, height)
```

----- ERLANG -- test@main@@Shape.erl
```erlang
-module(test@main@@Shape).
-export([area/1, '__bp_format'/1]).

area(Shape) ->
    case Shape of
        {test@main@@Shape__v__circle, Radius} ->
            ((Radius * Radius) * 3.14);
        {test@main@@Shape__v__square, Side} ->
            (Side * Side);
        {test@main@@Shape__v__triangle, Base, Height} ->
            ((Base * Height) * 0.5);
        _ ->
            0.0
    end.

'__bp_format'({test@main@@Shape__v__circle, F0}) -> {variant, "Shape.Circle", [{"radius", F0}]};
'__bp_format'({test@main@@Shape__v__square, F0}) -> {variant, "Shape.Square", [{"side", F0}]};
'__bp_format'({test@main@@Shape__v__triangle, F0, F1}) -> {variant, "Shape.Triangle", [{"base", F0}, {"height", F1}]}.
```

----- RUN LOG -----
```logs
```

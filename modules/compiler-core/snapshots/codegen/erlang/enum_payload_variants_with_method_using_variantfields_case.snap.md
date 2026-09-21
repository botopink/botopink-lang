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
-module(main).

%% type Shape
%%   Circle(radius)
%%   Square(side)
%%   Triangle(base, height)
```

----- ERLANG -- main__t__shape.erl
```erlang
-module(main__t__shape).
-export([area/1]).

area(Shape) ->
    case Shape of
        {'Circle', Radius} ->
            ((Radius * Radius) * 3.14);
        {'Square', Side} ->
            (Side * Side);
        {'Triangle', Base, Height} ->
            ((Base * Height) * 0.5);
        _ ->
            0.0
    end.
```

----- RUN LOG -----
```logs
```

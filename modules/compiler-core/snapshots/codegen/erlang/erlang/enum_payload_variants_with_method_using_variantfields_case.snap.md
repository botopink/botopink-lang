----- SOURCE CODE -- main.bp
```botopink
val Shape = enum {
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

%% enum Shape
%%   Circle(radius)
%%   Square(side)
%%   Triangle(base, height)

area(Shape) ->
    case Shape of
        {tag, Circle, Radius} ->
            ((Radius * Radius) * 3.14);
        {tag, Square, Side} ->
            (Side * Side);
        {tag, Triangle, Base, Height} ->
            ((Base * Height) * 0.5);
        _ ->
            0.0
    end.
```

----- RUN LOG -----
```logs
Error! main:main/0 is not exported.

Runtime terminating during boot ({undef,[{main,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

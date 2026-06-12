----- SOURCE CODE -- main.bp
```botopink
enum Shape {
    Circle(r: i32),
    Square(side: i32),
}
fn makeCircle() -> Shape {
    return Shape.Circle(r: 5);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% enum Shape
%%   Circle(r)
%%   Square(side)

makeCircle() ->
    {'Circle', 5}.
```

----- RUN LOG -----
```logs
```

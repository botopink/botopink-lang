----- SOURCE CODE -- main.bp
```botopink
type Shape {
    Circle(r: i32),
    Square(side: i32),
}
fn makeCircle() -> Shape {
    return Shape.Circle(r: 5);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Shape
%%   Circle(r)
%%   Square(side)

makeCircle() ->
    {test@main@@Shape__v__circle, 5}.
```

----- ERLANG -- test@main@@Shape.erl
```erlang
-module(test@main@@Shape).
-export(['__bp_format'/1]).

'__bp_format'({test@main@@Shape__v__circle, F0}) -> {variant, "Shape.Circle", [{"r", F0}]};
'__bp_format'({test@main@@Shape__v__square, F0}) -> {variant, "Shape.Square", [{"side", F0}]}.
```

----- RUN LOG -----
```logs
```

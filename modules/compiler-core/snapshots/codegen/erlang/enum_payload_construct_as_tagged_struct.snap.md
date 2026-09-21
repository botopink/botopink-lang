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
-module(main).

%% type Shape
%%   Circle(r)
%%   Square(side)

makeCircle() ->
    {main__t__shape__v__circle, 5}.
```

----- ERLANG -- main__t__shape.erl
```erlang
-module(main__t__shape).
-export(['__bp_format'/1]).

'__bp_format'({main__t__shape__v__circle, F0}) -> {variant, "Shape.Circle", [{"r", F0}]};
'__bp_format'({main__t__shape__v__square, F0}) -> {variant, "Shape.Square", [{"side", F0}]}.
```

----- RUN LOG -----
```logs
```

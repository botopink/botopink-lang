----- SOURCE CODE -- main.bp
```botopink
val Shape = type {
    Circle(r: i32),
    Square(s: i32),
}
fn big(sh: Shape) -> string {
    return case sh {
        Circle(r) if r > 10 -> "big circle";
        _ -> "other";
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type Shape
%%   Circle(r)
%%   Square(s)

big(Sh) ->
    case Sh of
        {main__t__shape__v__circle, R} when (R > 10) ->
            <<"big circle">>;
        _ ->
            <<"other">>
    end.
```

----- ERLANG -- main__t__shape.erl
```erlang
-module(main__t__shape).
-export(['__bp_format'/1]).

'__bp_format'({main__t__shape__v__circle, F0}) -> {variant, "Shape.Circle", [{"r", F0}]};
'__bp_format'({main__t__shape__v__square, F0}) -> {variant, "Shape.Square", [{"s", F0}]}.
```

----- RUN LOG -----
```logs
```

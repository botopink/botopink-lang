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
-module(test@main).

%% type Shape
%%   Circle(r)
%%   Square(s)

big(Sh) ->
    case Sh of
        {test@main@@Shape__v__circle, R} when (R > 10) ->
            <<"big circle">>;
        _ ->
            <<"other">>
    end.
```

----- ERLANG -- test@main@@Shape.erl
```erlang
-module(test@main@@Shape).
-export(['__bp_format'/1]).

'__bp_format'({test@main@@Shape__v__circle, F0}) -> {variant, "Shape.Circle", [{"r", F0}]};
'__bp_format'({test@main@@Shape__v__square, F0}) -> {variant, "Shape.Square", [{"s", F0}]}.
```

----- RUN LOG -----
```logs
```

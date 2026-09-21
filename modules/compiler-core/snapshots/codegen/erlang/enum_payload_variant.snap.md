----- SOURCE CODE -- main.bp
```botopink
val Color = type {
    Red,
    Rgb(r: i32, g: i32, b: i32),
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type Color
%%   Red
%%   Rgb(r, g, b)
```

----- ERLANG -- main__t__color.erl
```erlang
-module(main__t__color).
-export(['__bp_format'/1]).

'__bp_format'(main__t__color__v__red) -> {variant, "Color.Red", []};
'__bp_format'({main__t__color__v__rgb, F0, F1, F2}) -> {variant, "Color.Rgb", [{"r", F0}, {"g", F1}, {"b", F2}]}.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
type Direction {
    North,
    South,
    East,
    West,
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type Direction
%%   North
%%   South
%%   East
%%   West
```

----- ERLANG -- main__t__direction.erl
```erlang
-module(main__t__direction).
-export(['__bp_format'/1]).

'__bp_format'(main__t__direction__v__north) -> {variant, "Direction.North", []};
'__bp_format'(main__t__direction__v__south) -> {variant, "Direction.South", []};
'__bp_format'(main__t__direction__v__east) -> {variant, "Direction.East", []};
'__bp_format'(main__t__direction__v__west) -> {variant, "Direction.West", []}.
```

----- RUN LOG -----
```logs
```

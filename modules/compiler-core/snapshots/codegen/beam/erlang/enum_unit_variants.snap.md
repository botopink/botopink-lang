----- SOURCE CODE -- main.bp
```botopink
val Direction = type {
    North,
    South,
    East,
    West,
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Direction
%%   North
%%   South
%%   East
%%   West
```

----- ERLANG -- test@main@@Direction.erl
```erlang
-module(test@main@@Direction).
-export(['__bp_format'/1]).

'__bp_format'(test@main@@Direction__v__north) -> {variant, "Direction.North", []};
'__bp_format'(test@main@@Direction__v__south) -> {variant, "Direction.South", []};
'__bp_format'(test@main@@Direction__v__east) -> {variant, "Direction.East", []};
'__bp_format'(test@main@@Direction__v__west) -> {variant, "Direction.West", []}.
```

----- RUN LOG -----
```logs
```

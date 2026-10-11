----- SOURCE CODE -- main.bp
```botopink
val Color = type {
    Red,
    Green,
    Blue,
    fn name(self: Self) -> string {
        case (self) {
            Red -> "red";
            Green -> "green";
            Blue -> "blue";
        };
    }
};
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Color
%%   Red
%%   Green
%%   Blue
```

----- ERLANG -- test@main@@Color.erl
```erlang
-module(test@main@@Color).
-export([name/1, '__bp_format'/1]).

name(Self) ->
    case Self of
        test@main@@Color__v__red ->
            <<"red">>;
        test@main@@Color__v__green ->
            <<"green">>;
        test@main@@Color__v__blue ->
            <<"blue">>
    end.

'__bp_format'(test@main@@Color__v__red) -> {variant, "Color.Red", []};
'__bp_format'(test@main@@Color__v__green) -> {variant, "Color.Green", []};
'__bp_format'(test@main@@Color__v__blue) -> {variant, "Color.Blue", []}.
```

----- RUN LOG -----
```logs
```

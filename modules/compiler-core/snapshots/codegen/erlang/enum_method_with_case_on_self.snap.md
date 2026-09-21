----- SOURCE CODE -- main.bp
```botopink
val Color = type {
    Red,
    Green,
    Blue,
    fn name() -> string {
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
-module(main).

%% type Color
%%   Red
%%   Green
%%   Blue
```

----- ERLANG -- main__t__color.erl
```erlang
-module(main__t__color).
-export([name/0, '__bp_format'/1]).

name() ->
    case Self of
        main__t__color__v__red ->
            <<"red">>;
        main__t__color__v__green ->
            <<"green">>;
        main__t__color__v__blue ->
            <<"blue">>
    end.

'__bp_format'(main__t__color__v__red) -> {variant, "Color.Red", []};
'__bp_format'(main__t__color__v__green) -> {variant, "Color.Green", []};
'__bp_format'(main__t__color__v__blue) -> {variant, "Color.Blue", []}.
```

----- RUN LOG -----
```logs
```

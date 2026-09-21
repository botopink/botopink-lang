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
-export([name/0]).

name() ->
    case Self of
        'Red' ->
            <<"red">>;
        'Green' ->
            <<"green">>;
        'Blue' ->
            <<"blue">>
    end.
```

----- RUN LOG -----
```logs
```

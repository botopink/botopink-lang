----- SOURCE CODE -- main.bp
```botopink
val Color = enum {
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

%% enum Color
%%   Red
%%   Green
%%   Blue

name() ->
    case Self of
        Red ->
            <<"red">>;
        Green ->
            <<"green">>;
        Blue ->
            <<"blue">>
    end.
```

----- SOURCE CODE -- main.bp
```botopink
val Shape = enum {
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

%% enum Shape
%%   Circle(r)
%%   Square(s)

big(Sh) ->
    case Sh of
        {tag, Circle, R} ->
            <<"big circle">>;
        _ ->
            <<"other">>
    end.
```

----- RUN LOG -----
```logs
```

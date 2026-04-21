----- SOURCE CODE -- main.bp
```botopink
fn classify(day: i32) -> string {
    val kind = case day {
        6 | 7 -> "weekend";
        _ -> "weekday";
    };
    return kind;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

classify(Day) ->
    Kind = case Day of
        6 ->
            <<"weekend">>;
        7 ->
            <<"weekend">>;
        _ ->
            <<"weekday">>
    end,
    Kind.
```

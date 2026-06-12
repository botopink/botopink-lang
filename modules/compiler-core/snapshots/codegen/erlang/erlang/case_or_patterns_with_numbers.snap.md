----- SOURCE CODE -- main.bp
```botopink
fn classify(day: i32) -> string {
    val kind = case day {
        6 | 7 -> "weekend";
        _ -> "weekday";
    };
    @print(kind);
    return kind;
}
fn main() {
    classify(3);
    classify(6);
    classify(7);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

classify(Day) ->
    Kind = case Day of
        6 ->
            <<"weekend">>;
        7 ->
            <<"weekend">>;
        _ ->
            <<"weekday">>
    end,
    io:format("~p~n", [Kind]),
    Kind.

main() ->
    classify(3),
    classify(6),
    classify(7).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<<"weekday">>
<<"weekend">>
<<"weekend">>
```

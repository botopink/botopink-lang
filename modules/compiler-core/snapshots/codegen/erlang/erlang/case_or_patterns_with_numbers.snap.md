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

----- RUN LOG -----
```logs
Error! main:main/0 is not exported.

Runtime terminating during boot ({undef,[{main,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

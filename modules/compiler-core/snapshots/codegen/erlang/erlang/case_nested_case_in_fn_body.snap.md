----- SOURCE CODE -- main.bp
```botopink
fn process(x: i32) -> string {
    return case (x) {
        0 -> {
            break case (x) {
                0 -> "zero";
                _ -> "other";
            };
        };
        _ -> "non-zero";
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

process(X) ->
    case X of
        0 ->
            case X of
                0 ->
                    <<"zero">>;
                _ ->
                    <<"other">>
            end;
        _ ->
            <<"non-zero">>
    end.
```

----- RUN LOG -----
```logs
Error! main:main/0 is not exported.

Runtime terminating during boot ({undef,[{main,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

----- SOURCE CODE -- main.bp
```botopink
fn describe(n: i32) -> string {
    return if (n > 0) "positive" else "non-positive";
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

describe(N) ->
    case (N > 0) of
        true ->
            <<"positive">>;
        false ->
            <<"non-positive">>
    end.
```

----- RUN LOG -----
```logs
Error! main:main/0 is not exported.

Runtime terminating during boot ({undef,[{main,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

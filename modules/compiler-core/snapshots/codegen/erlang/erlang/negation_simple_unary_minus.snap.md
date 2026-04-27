----- SOURCE CODE -- main.bp
```botopink
fn negate(x: i32) -> i32 {
    return -x;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

negate(X) ->
    (-X).
```

----- RUN LOG -----
```logs
Error! main:main/0 is not exported.

Runtime terminating during boot ({undef,[{main,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

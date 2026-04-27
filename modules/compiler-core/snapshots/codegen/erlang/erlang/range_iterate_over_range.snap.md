----- SOURCE CODE -- main.bp
```botopink
fn sumTo(n: i32) -> i32 {
    return loop (0..n) { i ->
        yield i;
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

sumTo(N) ->
    lists:map(fun(I) ->
        I
    end, lists:seq(0, N)).
```

----- RUN LOG -----
```logs
Error! main:main/0 is not exported.

Runtime terminating during boot ({undef,[{main,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

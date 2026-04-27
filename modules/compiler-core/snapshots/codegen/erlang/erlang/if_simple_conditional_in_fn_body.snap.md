----- SOURCE CODE -- main.bp
```botopink
fn sign(n: i32) -> string {
    val r = if (n > 0) { "positive"; };
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

sign(N) ->
    R = case (N > 0) of
        true ->
            <<"positive">>
    end,
    R.
```

----- RUN LOG -----
```logs
Error! main:main/0 is not exported.

Runtime terminating during boot ({undef,[{main,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

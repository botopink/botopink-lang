----- SOURCE CODE -- main.bp
```botopink
fn process(f: syntax fn(x: i32) -> i32) -> i32 {
    return f(5);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

process(F) ->
    f(5).
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

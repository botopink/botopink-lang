----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert 42 = answer catch throw Error("not 42");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    case Answer of 42 -> Answer; _ -> erlang:throw(Error(<<"not 42">>)) end.
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

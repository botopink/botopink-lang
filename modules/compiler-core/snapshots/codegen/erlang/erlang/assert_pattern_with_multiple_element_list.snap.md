----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert [1, 2, 3] = numbers catch throw Error("not matching");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    case Numbers of [1, 2, 3] -> Numbers; _ -> erlang:throw(Error(<<"not matching">>)) end.
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

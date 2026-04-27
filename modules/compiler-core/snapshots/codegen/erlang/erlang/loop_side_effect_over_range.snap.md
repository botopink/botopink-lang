----- SOURCE CODE -- main.bp
```botopink
loop (0..10) { i ->
    @print(i);
};
```

----- ERLANG -- main.erl
```erlang
-module(main).

_loop() ->
    lists:foreach(fun(I) ->
        io:format("~p~n", [I])
    end, lists:seq(0, 10)).
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

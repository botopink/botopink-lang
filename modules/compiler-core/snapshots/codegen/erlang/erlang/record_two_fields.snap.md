----- SOURCE CODE -- main.bp
```botopink
val Point = record { x: i32, y: i32 }
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(Point, {x, y}).
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

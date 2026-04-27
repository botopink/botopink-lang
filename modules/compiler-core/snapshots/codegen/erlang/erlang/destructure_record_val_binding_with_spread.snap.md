----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32, z: i32 }
fn describe(p: Point) -> i32 {
    val { x, .. } = p;
    return x;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(Point, {x, y, z}).

describe(P) ->
    {X, _} = P,
    X.
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

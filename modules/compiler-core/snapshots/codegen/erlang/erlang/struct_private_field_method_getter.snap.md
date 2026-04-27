----- SOURCE CODE -- main.bp
```botopink
val Counter = struct {
    _count: i32 = 0,
    fn increment(self: Self) {
        self._count += 1;
    }
    get count(self: Self) -> i32 {
        return self._count;
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(Counter, {_count}).

increment() ->
    %% field += not directly supported in Erlang.
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

----- SOURCE CODE -- main.bp
```botopink
record Unimplemented { id: i32,
    fn process(self: Self) -> string {
        return @todo();
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(Unimplemented, {id}).

process() ->
    erlang:error({todo, "not implemented"}).
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

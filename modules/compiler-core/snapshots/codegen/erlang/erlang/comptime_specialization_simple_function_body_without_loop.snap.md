----- SOURCE CODE -- main.bp
```botopink
fn execute(comptime slug: string, input: i32) -> i32 {
    return input + 0;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
    val r3 = execute("calc", 5);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

main() ->
    R1 = execute_$0(10),
    R2 = execute_$1(42),
    R3 = execute_$0(5).

execute_$0(Input) ->
    (Input + 0).

execute_$1(Input) ->
    (Input + 0).
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

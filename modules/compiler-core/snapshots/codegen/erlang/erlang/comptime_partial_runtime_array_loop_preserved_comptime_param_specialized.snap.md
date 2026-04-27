----- SOURCE CODE -- main.bp
```botopink
val COMMANDS = ["calc", "noop", "help"];

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    loop (COMMANDS) { cmd ->
        if (cmd == slug) {
            output = input * 2;
        };
    };
    return output;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

COMMANDS() ->
    [<<"calc">>, <<"noop">>, <<"help">>].

main() ->
    R1 = execute_$0(10),
    R2 = execute_$1(42).

execute_$0(Input) ->
    Slug = <<"calc">>,
    Output = 0,
    lists:foreach(fun(Cmd) ->
        case (Cmd =:= Slug) of
            true ->
                Output = (Input * 2)
        end
    end, COMMANDS),
    Output.

execute_$1(Input) ->
    Slug = <<"noop">>,
    Output = 0,
    lists:foreach(fun(Cmd) ->
        case (Cmd =:= Slug) of
            true ->
                Output = (Input * 2)
        end
    end, COMMANDS),
    Output.
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

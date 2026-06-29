----- SOURCE CODE -- main.bp
```botopink
val COMMANDS = comptime ["calc", "noop", "help"];

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

----- COMPTIME ERLANG -- main.erl
```erlang
-module(comptime_45af6ab6cf9e497c).
-export([main/0]).
main() -> "[{\"id\":\"ct_0\",\"value\":[\"calc\",\"noop\",\"help\"]}]".
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).


main() ->
    R1 = 'execute_$0'(10),
    R2 = 'execute_$1'(42).

'execute_$0'(Input) ->
    Output = 0,
    Output = (Input * 2),
    Output.

'execute_$1'(Input) ->
    Output = 0,
    Output = (Input * 2),
    Output.

'_botopink_main'() ->
    COMMANDS = ["calc", "noop", "help"],
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

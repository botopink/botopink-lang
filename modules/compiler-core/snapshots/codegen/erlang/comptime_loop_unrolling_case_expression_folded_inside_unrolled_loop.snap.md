----- SOURCE CODE -- main.bp
```botopink
val COMMANDS = comptime ["calc", "noop", "help"];

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    loop (COMMANDS) { cmd ->
        if (cmd == slug) {
            output = case cmd {
                "calc" -> input * 2;
                "noop" -> input;
                _ -> 0;
            };
        };
    };
    return output;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val COMMANDS = comptime ["calc", "noop", "help"] → ["calc", "noop", "help"]
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

'COMMANDS'() ->
    ["calc", "noop", "help"].

main() ->
    R1 = 'execute_$0'(10),
    R2 = 'execute_$1'(42).

'execute_$0'(Input) ->
    Output = 0,
    Output@1 = (Input * 2),
    Output@1.

'execute_$1'(Input) ->
    Output = 0,
    Output@1 = Input,
    Output@1.

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

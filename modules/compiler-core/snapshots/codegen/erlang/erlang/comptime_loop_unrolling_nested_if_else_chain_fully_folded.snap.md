----- SOURCE CODE -- main.bp
```botopink
val COMMANDS = comptime ["calc", "noop", "help"];

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    loop (COMMANDS) { cmd ->
        if (cmd == slug) {
            if (cmd == "calc") {
                output = input * 2;
            } else if (cmd == "noop") {
                output = input;
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

----- COMPTIME ERLANG -- main.erl
```erlang
(module
  (import "wasi_snapshot_preview1" "fd_write"
    (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 8) "[{\"id\":\"ct_0\",\"value\":[\"calc\",\"noop\",\"help\"]}]")
  (func $main (export "_start")
    (i32.store (i32.const 0) (i32.const 8))
    (i32.store (i32.const 4) (i32.const 46))
    (drop (call $fd_write (i32.const 1) (i32.const 0) (i32.const 1) (i32.const 200))))
)
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
    Output = Input,
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

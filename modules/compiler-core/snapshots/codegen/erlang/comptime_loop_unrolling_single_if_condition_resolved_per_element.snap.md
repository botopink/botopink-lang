----- SOURCE CODE -- main.bp
```botopink
val COMMANDS = comptime ["calc", "noop", "help"];

fn execute(comptime slug: @Expr<string>, input: i32) -> i32 {
    var output = 0;
    for (COMMANDS) { cmd ->
        if (cmd == slug.value) {
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

----- COMPTIME VALUES -- main
```text
ct_0: val COMMANDS = comptime ["calc", "noop", "help"] → ["calc", "noop", "help"]
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

'COMMANDS'() ->
    [<<"calc">>, <<"noop">>, <<"help">>].

main() ->
    R1 = 'execute_$0'(10),
    R2 = 'execute_$1'(42).

'execute_$0'(Input) ->
    Output = 0,
    Output@1 = '__bp_int'((Input * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:7:28">>),
    Output@1.

'execute_$1'(Input) ->
    Output = 0,
    Output@1 = '__bp_int'((Input * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:7:28">>),
    Output@1.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

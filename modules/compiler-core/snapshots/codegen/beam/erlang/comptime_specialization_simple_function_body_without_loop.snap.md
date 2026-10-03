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
-module(test@main).
-export(['_botopink_main'/0, main/1]).

main() ->
    R1 = 'execute_$0'(10),
    R2 = 'execute_$1'(42),
    R3 = 'execute_$0'(5).

'execute_$0'(Input) ->
    '__bp_int'((Input + 0), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:2:18">>).

'execute_$1'(Input) ->
    '__bp_int'((Input + 0), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:2:18">>).

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

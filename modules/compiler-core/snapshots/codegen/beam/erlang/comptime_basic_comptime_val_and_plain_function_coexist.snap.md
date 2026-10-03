----- SOURCE CODE -- main.bp
```botopink
val x = comptime 1 + 2;

fn double(n: i32) -> i32 {
    return n * 2;
}

fn main() {
    val r = double(21);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val x = comptime 1 + 2 → 3
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

x() ->
    3.

double(N) ->
    '__bp_int'((N * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:4:14">>).

main() ->
    R = double(21).

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

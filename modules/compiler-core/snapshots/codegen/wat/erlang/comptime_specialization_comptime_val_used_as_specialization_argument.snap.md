----- SOURCE CODE -- main.bp
```botopink
val base = comptime 10 + 5;

fn scale(comptime factor: @Expr<i32>, value: i32) -> i32 {
    return value * factor.value;
}

fn main() {
    val doubled = scale(2, base);
    val tripled = scale(3, base);
    val doubledAgain = scale(2, 100);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val base = comptime 10 + 5 → 15
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

base() ->
    15.

main() ->
    Doubled = 'scale_$0'(base()),
    Tripled = 'scale_$1'(base()),
    DoubledAgain = 'scale_$0'(100).

'scale_$0'(Value) ->
    Factor = 2,
    '__bp_int'((Value * Factor), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:4:18">>).

'scale_$1'(Value) ->
    Factor = 3,
    '__bp_int'((Value * Factor), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:4:18">>).

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

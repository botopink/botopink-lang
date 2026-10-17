----- SOURCE CODE -- main.bp
```botopink
fn coerce(comptime v: @Expr<type<string | int | bool>>, x: i32) -> i32 {
    return x;
}

fn main() {
    val a = coerce("s", 1);
    val b = coerce(7, 2);
    val c = coerce("s", 3);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export(['__bp_priv__main'/0, '__bp_priv__coerce_$0'/1, '__bp_priv__coerce_$1'/1]).

main() ->
    A = 'coerce_$0'(1),
    B = 'coerce_$1'(2),
    C = 'coerce_$0'(3).

'coerce_$0'(X) ->
    X.

'coerce_$1'(X) ->
    X.

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__main'() -> main().

'__bp_priv__coerce_$0'(A0) -> 'coerce_$0'(A0).

'__bp_priv__coerce_$1'(A0) -> 'coerce_$1'(A0).
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
fn coerce(comptime v: type string | int | bool, x: i32) -> i32 {
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
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    A = coerce_$0(1),
    B = coerce_$1(2),
    C = coerce_$0(3).

coerce_$0(X) ->
    X.

coerce_$1(X) ->
    X.

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

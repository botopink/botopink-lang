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

----- COMPTIME ERLANG -- main.erl
```erlang
-module(comptime_45af6ab6cf9e497c).
-export([main/0]).
main() -> "[{\"id\":\"ct_0\",\"value\":3}]".
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).


double(N) ->
    (N * 2).

main() ->
    R = double(21).

'_botopink_main'() ->
    X = 3,
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
fn main() {
    // Initialize value
    val x = 1;
    // Return null
    null;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export(['__bp_priv__main'/0]).

main() ->
    % Initialize value
    X = 1,
    % Return null
    undefined.

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__main'() -> main().
```

----- RUN LOG -----
```logs
```

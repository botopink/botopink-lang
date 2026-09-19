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
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    % Initialize value
    X = 1,
    % Return null
    undefined.

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

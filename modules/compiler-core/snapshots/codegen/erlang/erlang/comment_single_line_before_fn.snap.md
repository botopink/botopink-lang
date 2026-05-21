----- SOURCE CODE -- main.bp
```botopink
// This is a comment
fn main() {
    null;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

% This is a comment

main() ->
    undefined.

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

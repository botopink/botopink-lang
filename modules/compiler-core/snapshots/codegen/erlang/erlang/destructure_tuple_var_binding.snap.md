----- SOURCE CODE -- main.bp
```botopink
fn main() {
    var #(x, y) = #(10, 20);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    {X, Y} = {10, 20}.

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

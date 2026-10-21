----- SOURCE CODE -- main.bp
```botopink
fn main() -> void {
    var #(x, y) = #(10, 20);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export(['__bp_priv__main'/0]).

main() ->
    {X, Y} = {10, 20}.

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

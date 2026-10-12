----- SOURCE CODE -- main.bp
```botopink
fn run() {
    @todo();
}
fn main() {
    run { x ->
        return "done";
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export(['__bp_priv__run'/0, '__bp_priv__main'/0]).

run() ->
    erlang:error({todo, <<"not implemented">>}).

main() ->
    run(fun(X) ->
        <<"done">>
    end).

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__run'() -> run().

'__bp_priv__main'() -> main().
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
fn main() -> string {
    val func: fn(string) -> string = {s ->
        return s;
    };
    return func("hello");
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export(['__bp_priv__main'/0]).

main() ->
    Func = fun(S) ->
        S
    end,
    Func(<<"hello">>).

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

----- SOURCE CODE -- main.bp
```botopink
fn main() -> string {
    val func = {s ->
        return s;
    };
    return func("hello");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    Func = fun(S) ->
        S
    end,
    Func(<<"hello">>).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

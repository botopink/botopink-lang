----- SOURCE CODE -- main.bp
```botopink
val greeting = "ola mundo";
pub fn pick(comptime q: @Expr<string>) -> @Expr<string> {
    val hit = q.lookup("greeting");
    if (hit) { b ->
        return b.ref();
    };
    return q.fail("greeting not found in caller scope");
}
val s = pick "x";
fn main() {
    @print(s);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).



main() ->
    io:format("~p~n", [S]).

'_botopink_main'() ->
    Greeting = <<"ola mundo">>,
    S = Greeting,
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

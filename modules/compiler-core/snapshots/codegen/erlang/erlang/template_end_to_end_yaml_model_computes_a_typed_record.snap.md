----- SOURCE CODE -- main.bp
```botopink
pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
    val t = q.text();
    return @expr(record { port: 8000 + t.length, debug: true });
}
val cfg = conf "yaml";
fn main() {
    @print(cfg.port + 1);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).


main() ->
    io:format("~p~n", [(maps:get(port, Cfg) + 1)]).

'_botopink_main'() ->
    Cfg = #{port => 8004, debug => true},
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

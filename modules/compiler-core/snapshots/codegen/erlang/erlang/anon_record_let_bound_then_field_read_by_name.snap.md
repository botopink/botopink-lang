----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val r = record { code: 7, kind: 11 };
    @print(r.kind);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    R = #{code => 7, kind => 11},
    io:format("~p~n", [maps:get(kind, R)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
11
```

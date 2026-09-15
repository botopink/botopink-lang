----- SOURCE CODE -- main.bp
```botopink
record R { a: i32, b: i32 }
fn main() {
    val r = R(a: 7, b: 11);
    @print(r.b);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% record R: a, b

main() ->
    R = #{a => 7, b => 11},
    io:format("~p~n", [maps:get(b, R)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
11
```

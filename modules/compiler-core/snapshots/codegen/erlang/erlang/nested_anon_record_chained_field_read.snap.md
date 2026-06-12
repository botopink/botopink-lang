----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val outer = record { span: record { start: 5, end: 9 }, kind: 3 };
    @print(outer.span.start);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    Outer = #{span => #{start => 5, end => 9}, kind => 3},
    io:format("~p~n", [maps:get(start, maps:get(span, Outer))]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

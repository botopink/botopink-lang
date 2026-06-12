----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "Hello,World";
    @print(s.toUpper());
    @print(s.toLower());
    @print(s.split(",").join("|"));
    @print(s.slice(0, 5));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    S = <<"Hello,World">>,
    io:format("~p~n", [string:uppercase(S)]),
    io:format("~p~n", [string:lowercase(S)]),
    io:format("~p~n", [iolist_to_binary(lists:join(<<"|">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, string:split(S, <<",">>, all))))]),
    io:format("~p~n", [string:slice(S, 0, ((5) - (0)))]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<<"HELLO,WORLD">>
<<"hello,world">>
<<"Hello|World">>
<<"Hello">>
```

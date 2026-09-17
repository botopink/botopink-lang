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

%% interface String

main() ->
    S = <<"Hello,World">>,
    '__bp_print'([string:uppercase(S)]),
    '__bp_print'([string:lowercase(S)]),
    '__bp_print'([iolist_to_binary(lists:join(<<"|">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, string:split(S, <<",">>, all))))]),
    '__bp_print'([string_slice(S, 0, 5)]).

string_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            string:slice(Self, Start, ((End) - (Start)));
        false ->
            string:slice(Self, Start)
    end.

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
HELLO,WORLD
hello,world
Hello|World
Hello
```

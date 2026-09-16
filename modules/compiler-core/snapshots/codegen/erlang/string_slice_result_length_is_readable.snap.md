----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "abcdef";
    val mid = s.slice(1, 5);
    @print(mid.len);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% interface String

main() ->
    S = <<"abcdef">>,
    Mid = string_slice(S, 1, 5),
    io:format("~p~n", [string:length(Mid)]).

string_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            string:slice(Self, Start, ((End) - (Start)));
        false ->
            string:slice(Self, Start)
    end.

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
4
```

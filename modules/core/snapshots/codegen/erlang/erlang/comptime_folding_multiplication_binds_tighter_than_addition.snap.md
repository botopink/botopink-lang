----- SOURCE CODE -- main.bp
```botopink
val n = comptime {
    break 2 + 3 * 4;
};
```

----- COMPTIME ERLANG -- main.erl
```erlang
-module(main).
-export([main/1]).

main(_) ->
    Values = [
        #{<<"id">> => <<"ct_0">>, <<"value">> => (2 + (3 * 4))}
    ],
    Json = json:encode(Values),
    io:format("~s~n", [Json]).
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% comptime val n
```

----- SOURCE CODE -- main.bp
```botopink
val pi2 = comptime {
    break 3.14 * 2.0;
};
```

----- COMPTIME ERLANG -- main.erl
```erlang
-module(main).
-export([main/1]).

main(_) ->
    Values = [
        #{<<"id">> => <<"ct_0">>, <<"value">> => (3.14 * 2.0)}
    ],
    Json = json:encode(Values),
    io:format("~s~n", [Json]).
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% comptime val pi2
```

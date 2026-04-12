----- SOURCE CODE -- main.bp
```botopink
val result = comptime 10 + 20;
```

----- COMPTIME ERLANG -- main.erl
```erlang
-module(main).
-export([main/1]).

main(_) ->
    Values = [
        #{<<"id">> => <<"ct_0">>, <<"value">> => (10 + 20)}
    ],
    Json = json:encode(Values),
    io:format("~s~n", [Json]).
```

----- ERLANG -- main.erl
```erlang
-module(main).

result() ->
    30.
```

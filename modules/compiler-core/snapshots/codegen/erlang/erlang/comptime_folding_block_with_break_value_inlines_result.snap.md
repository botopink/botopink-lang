----- SOURCE CODE -- main.bp
```botopink
val t = comptime {
    break 2 + 22;
};
```

----- COMPTIME ERLANG -- main.erl
```erlang
-module(main).
-export([main/1]).

main(_) ->
    Values = [
        #{<<"id">> => <<"ct_0">>, <<"value">> => (2 + 22)}
    ],
    Json = json:encode(Values),
    io:format("~s~n", [Json]).
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% comptime val t
```

----- RUN LOG -----
```logs
Error! main:main/0 is not exported.

Runtime terminating during boot ({undef,[{main,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

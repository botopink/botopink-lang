----- SOURCE CODE -- main.bp
```botopink
val rest = [3, 4];
val list = [1, 2, ..rest];
```

----- ERLANG -- main.erl
```erlang
-module(main).

rest() ->
    [3, 4].

list() ->
    [1, 2, rest].
```

----- RUN LOG -----
```logs
Error! main:main/0 is not exported.

Runtime terminating during boot ({undef,[{main,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

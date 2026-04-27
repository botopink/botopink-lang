----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val x = 10;
    @print(x * 2);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

main() ->
    X = 10,
    io:format("~p~n", [(X * 2)]).
```

----- RUN LOG -----
```logs
Error! main:main/0 is not exported.

Runtime terminating during boot ({undef,[{main,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

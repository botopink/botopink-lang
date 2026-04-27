----- SOURCE CODE -- main.bp
```botopink
val Color = enum {
    Red,
    Rgb(r: i32, g: i32, b: i32),
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% enum Color
%%   Red
%%   Rgb(r, g, b)
```

----- RUN LOG -----
```logs
Error! main:main/0 is not exported.

Runtime terminating during boot ({undef,[{main,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

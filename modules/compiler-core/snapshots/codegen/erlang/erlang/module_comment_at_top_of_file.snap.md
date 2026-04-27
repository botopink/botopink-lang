----- SOURCE CODE -- main.bp
```botopink
//// This module provides utility functions
//// for string manipulation

fn capitalize(s: string) -> string {
    return s;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%%% This module provides utility functions

%%% for string manipulation

capitalize(S) ->
    S.
```

----- RUN LOG -----
```logs
Error! main:main/0 is not exported.

Runtime terminating during boot ({undef,[{main,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

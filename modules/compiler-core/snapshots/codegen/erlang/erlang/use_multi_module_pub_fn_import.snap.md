----- SOURCE CODE -- math.bp
```botopink
pub fn double(x: i32) -> i32 {
    return x * 2;
}
```

----- ERLANG -- math.erl
```erlang
-module(math).
-export([double/1]).

double(X) ->
    (X * 2).
```

----- RUN LOG -----
```logs
Error! math:main/0 is not exported.

Runtime terminating during boot ({undef,[{math,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

----- SOURCE CODE -- main.bp
```botopink
use {double} from "math";
val result = double(21);
```

----- ERLANG -- main.erl
```erlang
-module(main).

-import(math, [double/0]).

result() ->
    double(21).
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

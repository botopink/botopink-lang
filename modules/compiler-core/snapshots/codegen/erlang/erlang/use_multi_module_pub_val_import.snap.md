----- SOURCE CODE -- config.bp
```botopink
pub val PORT = 8080;
pub val HOST = "localhost";
```

----- ERLANG -- config.erl
```erlang
-module(config).

PORT() ->
    8080.

HOST() ->
    <<"localhost">>.
```

----- RUN LOG -----
```logs
Error! Failed to load module 'config' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

----- SOURCE CODE -- main.bp
```botopink
use {PORT, HOST} from "config";
val addr = HOST;
val port = PORT;
```

----- ERLANG -- main.erl
```erlang
-module(main).

-import(config, [PORT/0, HOST/0]).

addr() ->
    HOST.

port() ->
    PORT.
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

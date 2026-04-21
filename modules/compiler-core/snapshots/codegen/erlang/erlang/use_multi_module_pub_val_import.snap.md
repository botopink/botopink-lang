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

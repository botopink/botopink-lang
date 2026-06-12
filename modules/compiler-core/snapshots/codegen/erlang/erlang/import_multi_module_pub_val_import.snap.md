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
```

----- SOURCE CODE -- main.bp
```botopink
import {PORT, HOST} from "config";
val addr = HOST;
val port = PORT;
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% import PORT, HOST

addr() ->
    HOST.

port() ->
    PORT.
```

----- RUN LOG -----
```logs
```

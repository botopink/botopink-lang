----- SOURCE CODE -- config.bp
```botopink
pub val PORT = 8080;
pub val HOST = "localhost";
```

----- ERLANG -- config.erl
```erlang
-module(test@config).
-export(['PORT'/0, 'HOST'/0]).

'PORT'() ->
    8080.

'HOST'() ->
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
-module(test@main).

%% import PORT, HOST

addr() ->
    test@config:'HOST'().

port() ->
    test@config:'PORT'().
```

----- RUN LOG -----
```logs
```

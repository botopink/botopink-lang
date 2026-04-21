----- SOURCE CODE -- main.bp
```botopink
pub val VERSION = 1;
pub val HOST = "localhost";
```

----- ERLANG -- main.erl
```erlang
-module(main).

VERSION() ->
    1.

HOST() ->
    <<"localhost">>.
```

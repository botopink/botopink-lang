----- SOURCE CODE -- main.bp
```botopink
pub val VERSION = 1;
pub val HOST = "localhost";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['VERSION'/0, 'HOST'/0]).

'VERSION'() ->
    1.

'HOST'() ->
    <<"localhost">>.
```

----- RUN LOG -----
```logs
```

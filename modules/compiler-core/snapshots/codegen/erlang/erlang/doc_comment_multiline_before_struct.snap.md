----- SOURCE CODE -- main.bp
```botopink
/// User account structure
/// Holds name and email
val Account = struct { name: string, email: string };
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% User account structure

%% Holds name and email

-record(Account, {name, email}).
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

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

----- SOURCE CODE -- main.bp
```botopink
/// User account structure
/// Holds name and email
val Account = struct { name: string, email: string };
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 2}.
%% User account structure
%% Holds name and email
```

----- RUN LOG -----
```logs
```

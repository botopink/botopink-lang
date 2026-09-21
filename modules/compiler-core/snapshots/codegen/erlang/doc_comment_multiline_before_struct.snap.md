----- SOURCE CODE -- main.bp
```botopink
/// User account structure
/// Holds name and email
val Account = type(name: string, email: string);
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% User account structure

%% Holds name and email

%% type Account: name, email
```

----- ERLANG -- main__t__account.erl
```erlang
-module(main__t__account).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> element(2, V);
'__bp_get'(V, email) -> element(3, V).

'__bp_format'(V) -> {record, "Account", [{"name", element(2, V)}, {"email", element(3, V)}]}.
```

----- RUN LOG -----
```logs
```

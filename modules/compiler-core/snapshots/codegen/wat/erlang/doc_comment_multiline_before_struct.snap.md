----- SOURCE CODE -- main.bp
```botopink
/// User account structure
/// Holds name and email
val Account = type(name: string, email: string);
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% User account structure

%% Holds name and email

%% type Account: name, email
```

----- ERLANG -- test@main@@Account.erl
```erlang
-module(test@main@@Account).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> element(2, V);
'__bp_get'(V, email) -> element(3, V).

'__bp_format'(V) -> {record, "Account", [{"name", element(2, V)}, {"email", element(3, V)}]}.
```

----- RUN LOG -----
```logs
```

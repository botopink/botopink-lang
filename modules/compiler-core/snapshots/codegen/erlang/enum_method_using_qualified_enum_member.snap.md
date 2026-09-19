----- SOURCE CODE -- main.bp
```botopink
val Status = type {
    Active,
    Inactive,
    fn isDefault(s: Self) -> string {
        val current = Status.Active;
        return current;
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type Status
%%   Active
%%   Inactive

isDefault(S) ->
    Current = 'Active',
    Current.
```

----- RUN LOG -----
```logs
```

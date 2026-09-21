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
```

----- ERLANG -- main__t__status.erl
```erlang
-module(main__t__status).
-export([isDefault/1]).

isDefault(S) ->
    Current = 'Active',
    Current.
```

----- RUN LOG -----
```logs
```

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
-export([isDefault/1, '__bp_format'/1]).

isDefault(S) ->
    Current = main__t__status__v__active,
    Current.

'__bp_format'(main__t__status__v__active) -> {variant, "Status.Active", []};
'__bp_format'(main__t__status__v__inactive) -> {variant, "Status.Inactive", []}.
```

----- RUN LOG -----
```logs
```

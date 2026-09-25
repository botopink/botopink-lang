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
-module(test@main).

%% type Status
%%   Active
%%   Inactive
```

----- ERLANG -- test@main@@Status.erl
```erlang
-module(test@main@@Status).
-export([isDefault/1, '__bp_format'/1]).

isDefault(S) ->
    Current = test@main@@Status__v__active,
    Current.

'__bp_format'(test@main@@Status__v__active) -> {variant, "Status.Active", []};
'__bp_format'(test@main@@Status__v__inactive) -> {variant, "Status.Inactive", []}.
```

----- RUN LOG -----
```logs
```

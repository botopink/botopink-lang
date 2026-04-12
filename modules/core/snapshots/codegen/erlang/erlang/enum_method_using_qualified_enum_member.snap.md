----- SOURCE CODE -- main.bp
```botopink
val Status = enum {
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

%% enum Status
%%   Active
%%   Inactive

isDefault(S) ->
    Current = Status_Active,
    Current.
```

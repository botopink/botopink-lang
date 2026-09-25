----- SOURCE CODE -- main.bp
```botopink
val Maybe = type {
    Nothing,
    Just(value: string),
    fn check(m: Self) -> string {
        return case m {
            Nothing -> "nothing";
            Just(value) -> "just";
        };
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Maybe
%%   Nothing
%%   Just(value)
```

----- ERLANG -- test@main@@Maybe.erl
```erlang
-module(test@main@@Maybe).
-export([check/1, '__bp_format'/1]).

check(M) ->
    case M of
        test@main@@Maybe__v__nothing ->
            <<"nothing">>;
        {test@main@@Maybe__v__just, Value} ->
            <<"just">>
    end.

'__bp_format'(test@main@@Maybe__v__nothing) -> {variant, "Maybe.Nothing", []};
'__bp_format'({test@main@@Maybe__v__just, F0}) -> {variant, "Maybe.Just", [{"value", F0}]}.
```

----- RUN LOG -----
```logs
```

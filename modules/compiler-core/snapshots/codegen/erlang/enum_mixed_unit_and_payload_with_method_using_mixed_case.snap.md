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
-module(main).

%% type Maybe
%%   Nothing
%%   Just(value)
```

----- ERLANG -- main__t__maybe.erl
```erlang
-module(main__t__maybe).
-export([check/1, '__bp_format'/1]).

check(M) ->
    case M of
        main__t__maybe__v__nothing ->
            <<"nothing">>;
        {main__t__maybe__v__just, Value} ->
            <<"just">>
    end.

'__bp_format'(main__t__maybe__v__nothing) -> {variant, "Maybe.Nothing", []};
'__bp_format'({main__t__maybe__v__just, F0}) -> {variant, "Maybe.Just", [{"value", F0}]}.
```

----- RUN LOG -----
```logs
```

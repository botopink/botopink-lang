----- SOURCE CODE -- main.bp
```botopink
val Maybe = enum {
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

%% enum Maybe
%%   Nothing
%%   Just(value)

check(M) ->
    case M of
        Nothing ->
            <<"nothing">>;
        {tag, Just, Value} ->
            <<"just">>
    end.
```

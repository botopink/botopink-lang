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
-export([check/1]).

check(M) ->
    case M of
        'Nothing' ->
            <<"nothing">>;
        {'Just', Value} ->
            <<"just">>
    end.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
fn first3() -> string {
    val s = "hello";
    return s.slice(0, 3);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% interface String

first3() ->
    S = <<"hello">>,
    string_slice(S, 0, 3).

string_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            string:slice(Self, Start, ((End) - (Start)));
        false ->
            string:slice(Self, Start)
    end.
```

----- RUN LOG -----
```logs
```

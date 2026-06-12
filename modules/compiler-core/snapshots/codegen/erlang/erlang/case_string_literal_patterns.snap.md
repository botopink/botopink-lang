----- SOURCE CODE -- main.bp
```botopink
fn greet(lang: string) -> string {
    val msg = case lang {
        "en" -> "hello";
        "pt" -> "ola";
        _ -> "hi";
    };
    @print(msg);
    return msg;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

greet(Lang) ->
    Msg = case Lang of
        <<"en">> ->
            <<"hello">>;
        <<"pt">> ->
            <<"ola">>;
        _ ->
            <<"hi">>
    end,
    io:format("~p~n", [Msg]),
    Msg.
```

----- RUN LOG -----
```logs
```

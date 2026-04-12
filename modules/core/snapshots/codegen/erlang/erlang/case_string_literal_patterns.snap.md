----- SOURCE CODE -- main.bp
```botopink
fn greet(lang: string) -> string {
    val msg = case lang {
        "en" -> "hello";
        "pt" -> "ola";
        else -> "hi";
    };
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
    Msg.
```

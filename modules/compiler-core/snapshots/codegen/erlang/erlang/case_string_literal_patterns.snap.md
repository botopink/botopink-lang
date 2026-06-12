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
fn main() {
    greet("en");
    greet("pt");
    greet("fr");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

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

main() ->
    greet(<<"en">>),
    greet(<<"pt">>),
    greet(<<"fr">>).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<<"hello">>
<<"ola">>
<<"hi">>
```

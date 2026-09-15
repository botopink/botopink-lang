----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val messages = ["Erro 404", "Sucesso 200", "Aviso 500"];
    loop (messages, 0..) { msg, i ->
        @print(msg);
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    Messages = [<<"Erro 404">>, <<"Sucesso 200">>, <<"Aviso 500">>],
    lists:foreach(fun(Msg, I) ->
        io:format("~p~n", [Msg])
    end, Messages).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

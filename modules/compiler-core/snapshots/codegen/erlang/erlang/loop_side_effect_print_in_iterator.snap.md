----- SOURCE CODE -- main.bp
```botopink
val messages = ["Erro 404", "Sucesso 200", "Aviso 500"];
loop (messages, 0..) { msg, i ->
    print("mensagem");
};
```

----- ERLANG -- main.erl
```erlang
-module(main).

messages() ->
    [<<"Erro 404">>, <<"Sucesso 200">>, <<"Aviso 500">>].

_loop() ->
    lists:foreach(fun(Msg, I) ->
        print(<<"mensagem">>)
    end, Messages).
```

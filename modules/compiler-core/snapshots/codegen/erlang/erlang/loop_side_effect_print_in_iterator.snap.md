----- SOURCE CODE -- main.bp
```botopink
val messages = ["Erro 404", "Sucesso 200", "Aviso 500"];
loop (messages, 0..) { msg, i ->
    @print(msg);
};
```

----- ERLANG -- main.erl
```erlang
-module(main).

messages() ->
    [<<"Erro 404">>, <<"Sucesso 200">>, <<"Aviso 500">>].

_loop() ->
    lists:foreach(fun(Msg, I) ->
        io:format("~p~n", [Msg])
    end, Messages).
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

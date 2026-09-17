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
    lists:foreach(fun({I, Msg}) ->
        '__bp_print'([Msg])
    end, lists:enumerate(0, Messages)).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
Erro 404
Sucesso 200
Aviso 500
```

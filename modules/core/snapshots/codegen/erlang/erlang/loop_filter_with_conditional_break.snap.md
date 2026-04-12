----- SOURCE CODE -- main.bp
```botopink
val precosBrutos = [100, 250, 400];
val apenasGrandes = loop (precosBrutos) { valor ->
    if (valor > 200) {
        break valor;
    };
};
```

----- ERLANG -- main.erl
```erlang
-module(main).

precosBrutos() ->
    [100, 250, 400].

apenasGrandes() ->
    lists:foreach(fun(Valor) ->
        case (Valor > 200) of
            true ->
                Valor
        end
    end, PrecosBrutos).
```

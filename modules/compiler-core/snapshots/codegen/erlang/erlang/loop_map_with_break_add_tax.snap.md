----- SOURCE CODE -- main.bp
```botopink
val precosBrutos = [100, 250, 400];
val precosComTaxa = loop (precosBrutos) { valor ->
    val taxa = valor * 0.15;
    break valor + taxa;
};
```

----- ERLANG -- main.erl
```erlang
-module(main).

precosBrutos() ->
    [100, 250, 400].

precosComTaxa() ->
    lists:foreach(fun(Valor) ->
        Taxa = (Valor * 0.15),
        (Valor + Taxa)
    end, PrecosBrutos).
```

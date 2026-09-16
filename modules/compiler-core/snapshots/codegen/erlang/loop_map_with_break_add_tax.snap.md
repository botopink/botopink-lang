----- SOURCE CODE -- main.bp
```botopink
val precosBrutos = [100, 250, 400];
val precosComTaxa = loop (precosBrutos) { valor ->
    val taxa = valor * 0.15;
    break valor + taxa;
};
fn main() {
    @print(precosComTaxa);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).



main() ->
    io:format("~p~n", [PrecosComTaxa]).

'_botopink_main'() ->
    PrecosBrutos = [100, 250, 400],
    PrecosComTaxa = lists:foreach(fun(Valor) ->
        Taxa = (Valor * 0.15),
        (Valor + Taxa)
    end, PrecosBrutos),
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
COMPILE ERROR (erlc):
main.erl:7:24: variable 'PrecosComTaxa' is unbound
```

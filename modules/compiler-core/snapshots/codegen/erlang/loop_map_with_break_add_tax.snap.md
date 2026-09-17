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

precosBrutos() ->
    [100, 250, 400].

precosComTaxa() ->
    lists:map(fun(Valor) ->
        Taxa = (Valor * 0.15),
        (Valor + Taxa)
    end, precosBrutos()).

main() ->
    '__bp_print'([precosComTaxa()]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
[115.0,287.5,460.0]
```

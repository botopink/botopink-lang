----- SOURCE CODE -- main.bp
```botopink
val precosBrutos = [100, 250, 400];
val apenasGrandes = loop (precosBrutos) { valor ->
    if (valor > 200) {
        break valor;
    };
};
fn main() {
    @print(apenasGrandes);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

precosBrutos() ->
    [100, 250, 400].

apenasGrandes() ->
    lists:filtermap(fun(Valor) ->
        case (Valor > 200) of
            true ->
                {true, Valor};
            _ -> false
        end
    end, precosBrutos()).

main() ->
    io:format("~p~n", [apenasGrandes()]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
[250,400]
```

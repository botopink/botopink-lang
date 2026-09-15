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



main() ->
    io:format("~p~n", [ApenasGrandes]).

'_botopink_main'() ->
    PrecosBrutos = [100, 250, 400],
    ApenasGrandes = lists:foreach(fun(Valor) ->
        case (Valor > 200) of
            true ->
                Valor;
            _ -> ok
        end
    end, PrecosBrutos),
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

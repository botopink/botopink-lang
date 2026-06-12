----- SOURCE CODE -- main.bp
```botopink
fn main() -> string {
    val input = 42;
    val status = @block{
        val calculo = input * 2;
        if (calculo > 100) return "Alto";
        return "Baixo";
    };
    return status;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    Input = 42,
    Status = (fun() ->
        Calculo = (Input * 2),
        case (Calculo > 100) of
            true ->
                <<"Alto">>;
            _ ->
                <<"Baixo">>
        end
    end)(),
    Status.

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

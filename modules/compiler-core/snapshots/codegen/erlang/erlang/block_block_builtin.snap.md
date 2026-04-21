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

main() ->
    Input = 42,
    Status = fun() ->
begin
            Calculo = (Input * 2),
            case (Calculo > 100) of
                true ->
                    <<"Alto">>
            end,
            <<"Baixo">>
        end
    end
,
    Status.
```

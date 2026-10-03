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
-module(test@main).
-export(['_botopink_main'/0, main/1]).

main() ->
    Input = 42,
    Status = (fun() ->
        Calculo = '__bp_int'((Input * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:4:29">>),
        case (Calculo > 100) of
            true ->
                <<"Alto">>;
            _ ->
                <<"Baixo">>
        end
    end)(),
    Status.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

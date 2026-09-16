----- SOURCE CODE -- main.bp
```botopink
fn build(comptime prefix: string, name: string) -> string {
    return prefix + ": " + name;
}

fn main() {
    val r1 = build("INFO", "Sistema iniciado");
    val r2 = build("INFO", "Log replicado");
    @print(r1);
    @print(r2);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    R1 = 'build_$0'(<<"Sistema iniciado">>),
    R2 = 'build_$0'(<<"Log replicado">>),
    io:format("~p~n", [R1]),
    io:format("~p~n", [R2]).

'build_$0'(Name) ->
    Prefix = <<"INFO">>,
    <<Prefix/binary, ": ", Name/binary>>.

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<<"INFO: Sistema iniciado">>
<<"INFO: Log replicado">>
```

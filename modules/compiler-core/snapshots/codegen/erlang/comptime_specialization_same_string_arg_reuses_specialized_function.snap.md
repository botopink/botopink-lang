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
    '__bp_print'([R1]),
    '__bp_print'([R2]).

'build_$0'(Name) ->
    Prefix = <<"INFO">>,
    <<Prefix/binary, ": ", Name/binary>>.

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
INFO: Sistema iniciado
INFO: Log replicado
```

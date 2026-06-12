----- SOURCE CODE -- main.bp
```botopink
fn build(prefix comptime: string, name: string) -> string {
    return prefix + ": " + name;
}

fn main() {
    val r1 = build("INFO", "Sistema iniciado");
    val r2 = build("WARN", "Memória alta");
    val r3 = build("INFO", "Log replicado");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    R1 = build_$0(<<"Sistema iniciado">>),
    R2 = build_$1(<<"Memória alta">>),
    R3 = build_$0(<<"Log replicado">>).

build_$0(Name) ->
    Prefix = <<"INFO">>,
    ((Prefix + <<": ">>) + Name).

build_$1(Name) ->
    Prefix = <<"WARN">>,
    ((Prefix + <<": ">>) + Name).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

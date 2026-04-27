----- SOURCE CODE -- main.bp
```botopink
fn build(comptime prefix: string, name: string) -> string {
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
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

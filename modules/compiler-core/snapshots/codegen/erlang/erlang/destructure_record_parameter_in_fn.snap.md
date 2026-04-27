----- SOURCE CODE -- main.bp
```botopink
record Person { name: string, age: i32 }
fn greet({ name, .. }: Person) -> string {
    return name;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(Person, {name, age}).

greet({Name, _}) ->
    Name.
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

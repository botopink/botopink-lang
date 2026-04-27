----- SOURCE CODE -- main.bp
```botopink
/// This function greets the user
fn greet(name: string) -> string {
    return name;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% This function greets the user

greet(Name) ->
    Name.
```

----- RUN LOG -----
```logs
Error! main:main/0 is not exported.

Runtime terminating during boot ({undef,[{main,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

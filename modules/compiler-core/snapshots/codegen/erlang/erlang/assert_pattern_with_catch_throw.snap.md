----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert Person(name, age) = r catch throw Error("is not person");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    case R of {tag, Person, Name, Age} -> R; _ -> erlang:throw(Error(<<"is not person">>)) end.
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

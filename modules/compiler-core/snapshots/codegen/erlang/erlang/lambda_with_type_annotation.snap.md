----- SOURCE CODE -- main.bp
```botopink
fn main() -> string {
    val func: fn(String)-> string = {s ->
        return s;
    };
    return func("hello");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

main() ->
    Func = fun(S) ->
        S
    end,
    func(<<"hello">>).
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

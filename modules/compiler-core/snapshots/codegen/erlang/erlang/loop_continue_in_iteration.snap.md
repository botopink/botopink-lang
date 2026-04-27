----- SOURCE CODE -- main.bp
```botopink
fn sumEvens(arr: i32[]) -> i32 {
    return loop (arr) { x ->
        if (x % 2 != 0) { continue; };
        yield x;
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

sumEvens(Arr) ->
    lists:map(fun(X) ->
        case ((X rem 2) =/= 0) of
            true ->
                %% continue
        end,
        X
    end, Arr).
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

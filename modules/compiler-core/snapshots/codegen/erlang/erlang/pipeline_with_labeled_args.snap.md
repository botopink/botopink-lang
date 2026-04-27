----- SOURCE CODE -- main.bp
```botopink
fn double(x: i32) -> i32 { return x * 2; }
fn inc(x: i32) -> i32 { return x + 1; }
fn main() {
    val result = 1
        |> double
        |> inc;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

double(X) ->
    (X * 2).

inc(X) ->
    (X + 1).

main() ->
    Result = Inc(Double(1)).
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

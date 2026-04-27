----- SOURCE CODE -- main.bp
```botopink
record Error { msg: string }
fn fetch() -> #(i32, i32) {
    return #(1, 2);
}
fn f() {
    val #(a, b) = try fetch() catch throw Error(msg: "failed");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(Error, {msg}).

fetch() ->
    {1, 2}.

f() ->
    {A, B} = try
        fetch()
catch
        _Err ->
            erlang:throw(Error(<<"failed">>))
end.
```

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

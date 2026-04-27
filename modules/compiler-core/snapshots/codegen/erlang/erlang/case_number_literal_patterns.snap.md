----- SOURCE CODE -- main.bp
```botopink
fn classify(n: i32) -> string {
    val result = case n {
        0 -> "zero";
        1 -> "one";
        _ -> "many";
    };
    return result;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

classify(N) ->
    Result = case N of
        0 ->
            <<"zero">>;
        1 ->
            <<"one">>;
        _ ->
            <<"many">>
    end,
    Result.
```

----- RUN LOG -----
```logs
Error! main:main/0 is not exported.

Runtime terminating during boot ({undef,[{main,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

----- SOURCE CODE -- main.bp
```botopink
val parity = case 5 {
    0 | 2 | 4 -> "even";
    _      -> {
        val value = "odd";
        break value;
    };
};
```

----- ERLANG -- main.erl
```erlang
-module(main).

parity() ->
    case 5 of
        0 ->
            <<"even">>;
        2 ->
            <<"even">>;
        4 ->
            <<"even">>;
        _ ->
            Value = <<"odd">>,
            Value
    end.
```

----- RUN LOG -----
```logs
Error! main:main/0 is not exported.

Runtime terminating during boot ({undef,[{main,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

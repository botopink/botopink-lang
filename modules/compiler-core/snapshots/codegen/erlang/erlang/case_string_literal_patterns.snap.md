----- SOURCE CODE -- main.bp
```botopink
fn greet(lang: string) -> string {
    val msg = case lang {
        "en" -> "hello";
        "pt" -> "ola";
        _ -> "hi";
    };
    return msg;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

greet(Lang) ->
    Msg = case Lang of
        <<"en">> ->
            <<"hello">>;
        <<"pt">> ->
            <<"ola">>;
        _ ->
            <<"hi">>
    end,
    Msg.
```

----- RUN LOG -----
```logs
Error! main:main/0 is not exported.

Runtime terminating during boot ({undef,[{main,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

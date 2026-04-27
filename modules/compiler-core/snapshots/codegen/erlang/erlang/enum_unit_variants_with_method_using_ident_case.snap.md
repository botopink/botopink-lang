----- SOURCE CODE -- main.bp
```botopink
val HttpMethod = enum {
    Get,
    Post,
    Put,
    Delete,
    fn name(m: Self) -> string {
        val label = case m {
            Get -> "GET";
            Post -> "POST";
            Put -> "PUT";
            _ -> "DELETE";
        };
        return label;
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% enum HttpMethod
%%   Get
%%   Post
%%   Put
%%   Delete

name(M) ->
    Label = case M of
        Get ->
            <<"GET">>;
        Post ->
            <<"POST">>;
        Put ->
            <<"PUT">>;
        _ ->
            <<"DELETE">>
    end,
    Label.
```

----- RUN LOG -----
```logs
Error! main:main/0 is not exported.

Runtime terminating during boot ({undef,[{main,main,[],[]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```

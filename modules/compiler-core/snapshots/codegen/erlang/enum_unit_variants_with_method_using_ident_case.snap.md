----- SOURCE CODE -- main.bp
```botopink
val HttpMethod = type {
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

%% type HttpMethod
%%   Get
%%   Post
%%   Put
%%   Delete

name(M) ->
    Label = case M of
        'Get' ->
            <<"GET">>;
        'Post' ->
            <<"POST">>;
        'Put' ->
            <<"PUT">>;
        _ ->
            <<"DELETE">>
    end,
    Label.
```

----- RUN LOG -----
```logs
```

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
-module(test@main).

%% type HttpMethod
%%   Get
%%   Post
%%   Put
%%   Delete
```

----- ERLANG -- test@main@@HttpMethod.erl
```erlang
-module(test@main@@HttpMethod).
-export([name/1, '__bp_format'/1]).

name(M) ->
    Label = case M of
        test@main@@HttpMethod__v__get ->
            <<"GET">>;
        test@main@@HttpMethod__v__post ->
            <<"POST">>;
        test@main@@HttpMethod__v__put ->
            <<"PUT">>;
        _ ->
            <<"DELETE">>
    end,
    Label.

'__bp_format'(test@main@@HttpMethod__v__get) -> {variant, "HttpMethod.Get", []};
'__bp_format'(test@main@@HttpMethod__v__post) -> {variant, "HttpMethod.Post", []};
'__bp_format'(test@main@@HttpMethod__v__put) -> {variant, "HttpMethod.Put", []};
'__bp_format'(test@main@@HttpMethod__v__delete) -> {variant, "HttpMethod.Delete", []}.
```

----- RUN LOG -----
```logs
```

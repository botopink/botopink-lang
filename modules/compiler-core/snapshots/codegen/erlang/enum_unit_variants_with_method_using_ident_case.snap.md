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
```

----- ERLANG -- main__t__httpmethod.erl
```erlang
-module(main__t__httpmethod).
-export([name/1, '__bp_format'/1]).

name(M) ->
    Label = case M of
        main__t__httpmethod__v__get ->
            <<"GET">>;
        main__t__httpmethod__v__post ->
            <<"POST">>;
        main__t__httpmethod__v__put ->
            <<"PUT">>;
        _ ->
            <<"DELETE">>
    end,
    Label.

'__bp_format'(main__t__httpmethod__v__get) -> {variant, "HttpMethod.Get", []};
'__bp_format'(main__t__httpmethod__v__post) -> {variant, "HttpMethod.Post", []};
'__bp_format'(main__t__httpmethod__v__put) -> {variant, "HttpMethod.Put", []};
'__bp_format'(main__t__httpmethod__v__delete) -> {variant, "HttpMethod.Delete", []}.
```

----- RUN LOG -----
```logs
```

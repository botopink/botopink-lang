----- SOURCE CODE -- main.bp
```botopink
record Error { msg: string }
*fn fetch() -> @Result<#(i32, i32), Error> {
    throw Error(msg: "boom");
}
fn f() {
    val #(a, b) = try fetch() catch throw Error(msg: "failed");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record Error: msg

fetch() ->
    {error, #{msg => <<"boom">>}}.

f() ->
    {A, B} = case fetch() of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            erlang:throw(#{msg => <<"failed">>})
    end.
```

----- RUN LOG -----
```logs
```

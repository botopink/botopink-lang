----- SOURCE CODE -- main.bp
```botopink
record R { a: i32, b: i32 }
fn pick(maybe: ?R) -> i32 {
    return maybe?.b;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record R: a, b

pick(Maybe) ->
    (fun(undefined) -> undefined; (_Opt0) -> maps:get(b, _Opt0) end)(Maybe).
```

----- RUN LOG -----
```logs
```

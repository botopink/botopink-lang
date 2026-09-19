----- SOURCE CODE -- main.bp
```botopink
type R(a: i32, b: i32)
fn pick(maybe: ?R) -> ?i32 {
    return maybe?.b;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type R: a, b

pick(Maybe) ->
    (fun(undefined) -> undefined; (_Opt0) -> maps:get(b, _Opt0) end)(Maybe).
```

----- RUN LOG -----
```logs
```

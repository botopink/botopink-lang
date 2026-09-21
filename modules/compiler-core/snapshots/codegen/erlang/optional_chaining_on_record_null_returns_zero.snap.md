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
    (fun(undefined) -> undefined; (_Opt0) -> element(3, _Opt0) end)(Maybe).
```

----- ERLANG -- main__t__r.erl
```erlang
-module(main__t__r).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, a) -> element(2, V);
'__bp_get'(V, b) -> element(3, V).

'__bp_format'(V) -> {record, "R", [{"a", element(2, V)}, {"b", element(3, V)}]}.
```

----- RUN LOG -----
```logs
```

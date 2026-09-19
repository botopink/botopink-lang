----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val list: i32[] = [];
    val assert [] = list catch throw "not empty";
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    List = [],
    case List of [] -> List; _ -> erlang:throw(<<"not empty">>) end.
```

----- RUN LOG -----
```logs
```

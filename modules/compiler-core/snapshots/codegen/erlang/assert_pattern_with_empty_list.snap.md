----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert [] = list catch throw Error("not empty");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    case List of [] -> List; _ -> erlang:throw({error, <<"not empty">>}) end.
```

----- RUN LOG -----
```logs
```

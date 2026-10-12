----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val list: i32[] = [];
    val assert [] = list catch throw "not empty";
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__f'/0]).

f() ->
    List = [],
    case List of [] -> List; _ -> erlang:throw(<<"not empty">>) end.

'__bp_priv__f'() -> f().
```

----- RUN LOG -----
```logs
```

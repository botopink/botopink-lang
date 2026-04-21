----- SOURCE CODE -- main.bp
```botopink
fn main() -> string {
    val func = {s ->
        return s;
    };
    return func("hello");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

main() ->
    Func = fun(S) ->
        S
    end,
    func(<<"hello">>).
```

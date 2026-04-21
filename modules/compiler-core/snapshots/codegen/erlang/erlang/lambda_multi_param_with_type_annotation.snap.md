----- SOURCE CODE -- main.bp
```botopink
fn main() -> i32 {
    val add: fn(i32,i32)-> i32 = {a, b ->
        return a + b;
    };
    return add(10, 20);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

main() ->
    Add = fun(A, B) ->
        (A + B)
    end,
    add(10, 20).
```

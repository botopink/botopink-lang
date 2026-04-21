----- SOURCE CODE -- main.bp
```botopink
fn calc(factor: i32) -> i32 {
    @todo();
}
fn main() {
    val r = calc(2) { a, b ->
        return 0;
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

calc(Factor) ->
    erlang:error({todo, "not implemented"}).

main() ->
    R = calc(2, fun(A, B) ->
        0
    end).
```

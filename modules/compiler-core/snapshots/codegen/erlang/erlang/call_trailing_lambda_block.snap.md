----- SOURCE CODE -- main.bp
```botopink
fn run() {
    @todo();
}
fn main() {
    run { x ->
        return "done";
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

run() ->
    erlang:error({todo, "not implemented"}).

main() ->
    run(fun(X) ->
        <<"done">>
    end).
```

----- SOURCE CODE -- main.bp
```botopink
fn doubles(arr: i32[]) -> i32[] {
    return loop (arr) { x ->
        yield x * 2;
    };
}
fn main() {
    @print(doubles([1, 2, 3]));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

doubles(Arr) ->
    lists:map(fun(X) ->
        (X * 2)
    end, Arr).

main() ->
    io:format("~p~n", [doubles([1, 2, 3])]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
[2,4,6]
```

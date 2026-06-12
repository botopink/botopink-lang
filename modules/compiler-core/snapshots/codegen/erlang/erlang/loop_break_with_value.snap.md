----- SOURCE CODE -- main.bp
```botopink
fn find(arr: i32[]) -> i32 {
    return loop (arr) { x ->
        if (x > 10) { break x; };
    };
}
fn main() {
    @print(find([5, 8, 15, 20]));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

find(Arr) ->
    lists:foreach(fun(X) ->
        case (X > 10) of
            true ->
                X;
            _ -> ok
        end
    end, Arr).

main() ->
    io:format("~p~n", [find([5, 8, 15, 20])]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
ok
```

----- SOURCE CODE -- main.bp
```botopink
fn main() -> bool {
    return isEven(10);
}

fn isEven(n: i32) -> bool {
    if (n == 0) { return true; };
    return isOdd(n - 1);
}

fn isOdd(n: i32) -> bool {
    if (n == 0) { return false; };
    return isEven(n - 1);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    isEven(10).

isEven(N) ->
    case (N =:= 0) of
        true ->
            true;
        _ ->
            isOdd((N - 1))
    end.

isOdd(N) ->
    case (N =:= 0) of
        true ->
            false;
        _ ->
            isEven((N - 1))
    end.

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

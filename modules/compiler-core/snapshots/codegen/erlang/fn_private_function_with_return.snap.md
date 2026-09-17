----- SOURCE CODE -- main.bp
```botopink
fn double(x: i32) -> i32 {
    return x * 2;
}
val result = double(5);
fn main() {
    @print(result);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

double(X) ->
    (X * 2).

result() ->
    double(5).

main() ->
    '__bp_print'([result()]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
10
```

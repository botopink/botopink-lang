----- SOURCE CODE -- main.bp
```botopink
fn double(x: i32) -> i32 {
    val result = x * 2;
    return result;
}
val output = double(10);
fn main() {
    @print(output);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

double(X) ->
    Result = (X * 2),
    Result.

output() ->
    double(10).

main() ->
    '__bp_print'([output()]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
20
```

----- SOURCE CODE -- main.bp
```botopink
record R { a: i32, b: i32 }
fn main() {
    val r = R(a: 7, b: 11);
    @print(r.b);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% record R: a, b

main() ->
    R = #{a => 7, b => 11},
    '__bp_print'([maps:get(b, R)]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
11
```

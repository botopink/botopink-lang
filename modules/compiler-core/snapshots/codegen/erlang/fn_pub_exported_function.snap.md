----- SOURCE CODE -- main.bp
```botopink
pub fn add(a: i32, b: i32) -> i32 {
    return a + b;
}
val result = add(3, 4);
fn main() {
    @print(result);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).
-export([add/2]).

add(A, B) ->
    (A + B).

result() ->
    add(3, 4).

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
7
```

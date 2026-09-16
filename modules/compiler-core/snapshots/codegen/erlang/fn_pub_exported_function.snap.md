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
    io:format("~p~n", [result()]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
7
```

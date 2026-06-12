----- SOURCE CODE -- main.bp
```botopink
pub fn max(a: i32, b: i32) -> i32 {
    if (a < b) {
        return b;
    } else {
        return a;
    }
}
fn main() {
    @print(max(3, 7));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).
-export([max/2]).

max(A, B) ->
    case (A < B) of
        true ->
            B;
        false ->
            A
    end.

main() ->
    io:format("~p~n", [max(3, 7)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
7
```

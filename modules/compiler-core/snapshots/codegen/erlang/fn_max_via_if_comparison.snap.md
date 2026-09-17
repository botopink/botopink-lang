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
-compile({no_auto_import,[max/2]}).
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
    '__bp_print'([max(3, 7)]).

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

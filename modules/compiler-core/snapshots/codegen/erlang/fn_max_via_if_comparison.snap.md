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
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(",", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> io_lib:format("~p", [V]);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(",", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
7
```

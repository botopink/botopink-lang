----- SOURCE CODE -- main.bp
```botopink
type Cell(
    value: i32,
    set: fn(next: i32) -> i32,
)

fn mk(v: i32) -> Cell {
    return Cell(value: v, set: { next -> next + v });
}

pub fn main() {
    val c = mk(5);
    @print(c.value);
    @print(c.set(9));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).
-export([main/0]).

%% type Cell: value, set

mk(V) ->
    #{value => V, set => fun(Next) ->
        (Next + V)
    end}.

main() ->
    C = mk(5),
    '__bp_print'([maps:get(value, C)]),
    '__bp_print'([(maps:get(set, C))(9)]).

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
5
14
```

----- SOURCE CODE -- main.bp
```botopink
type Stub(n: i32) {
    fn where(self: Self) -> SourceLocation {
        return @src();
    }
}
fn main() {
    val loc = Stub(n: 1).where();
    @print(loc.file, loc.line, loc.column, loc.fnName);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% type SourceLocation: file, line, column, fnName

%% type Stub: n

main() ->
    Loc = main__t__stub:where(#{n => 1}),
    '__bp_print'([maps:get(file, Loc), maps:get(line, Loc), maps:get(column, Loc), maps:get(fnName, Loc)]).

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

----- ERLANG -- main__t__stub.erl
```erlang
-module(main__t__stub).
-export([where/1]).

where(Self) ->
    #{file => <<"main.bp">>, line => 3, column => 16, fnName => <<"Stub.where">>}.
```

----- RUN LOG -----
```logs
main.bp 3 16 Stub.where
```

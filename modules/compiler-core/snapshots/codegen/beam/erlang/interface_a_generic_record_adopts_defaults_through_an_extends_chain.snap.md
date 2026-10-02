----- SOURCE CODE -- main.bp
```botopink
behavior Sized {
    fn size(self: Self) -> i32;

    default fn isEmpty(self: Self) -> bool {
        return self.size() == 0;
    }
}

behavior Counted extends Sized {
    default fn twiceSize(self: Self) -> i32 {
        return self.size() * 2;
    }
}

type Bag<T>(
    items: Array<T>,
) implement Counted {
    pub fn size(self: Self<T>) -> i32 {
        return self.items.length;
    }
}

fn main() {
    @print(Bag(items: []).isEmpty());
    @print(Bag(items: [1]).isEmpty());
    @print(Bag(items: [1, 2]).twiceSize());
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

%% behavior Sized

%% behavior Counted

%% type Bag: items

main() ->
    '__bp_print'([test@main@@Bag:isEmpty({test@main@@Bag, []})]),
    '__bp_print'([test@main@@Bag:isEmpty({test@main@@Bag, [1]})]),
    '__bp_print'([test@main@@Bag:twiceSize({test@main@@Bag, [1, 2]})]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when erlang:is_tuple(V), erlang:tuple_size(V) > 0, erlang:is_atom(erlang:element(1, V)), erlang:element(1, V) =/= true, erlang:element(1, V) =/= false, erlang:element(1, V) =/= undefined -> '__bp_tagged'(erlang:element(1, V), V);
'__bp_show'(V, _) when erlang:is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- erlang:tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when erlang:is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(erlang:atom_to_list(A), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(erlang:apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().
```

----- ERLANG -- test@main@@Bag.erl
```erlang
-module(test@main@@Bag).
-compile({no_auto_import,[size/1]}).
-export([size/1, twiceSize/1, isEmpty/1, '__bp_get'/2, '__bp_format'/1]).

size(Self) ->
    erlang:length(erlang:element(2, Self)).

twiceSize(Self) ->
    (size(Self) * 2).

isEmpty(Self) ->
    (size(Self) =:= 0).

'__bp_get'(V, items) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Bag", [{"items", erlang:element(2, V)}]}.
```

----- RUN LOG -----
```logs
true
false
4
```

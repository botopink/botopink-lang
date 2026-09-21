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
    pub fn size(self: Self) -> i32 {
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
-module(main).
-export(['_botopink_main'/0, main/1]).

%% behavior Sized

%% behavior Counted

%% type Bag: items

main() ->
    '__bp_print'([main__t__bag:isEmpty(#{items => []})]),
    '__bp_print'([main__t__bag:isEmpty(#{items => [1]})]),
    '__bp_print'([main__t__bag:twiceSize(#{items => [1, 2]})]).

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

----- ERLANG -- main__t__bag.erl
```erlang
-module(main__t__bag).
-compile({no_auto_import,[size/1]}).
-export([size/1, twiceSize/1, isEmpty/1]).

size(Self) ->
    length(maps:get(items, Self)).

twiceSize(Self) ->
    (size(Self) * 2).

isEmpty(Self) ->
    (size(Self) =:= 0).
```

----- RUN LOG -----
```logs
true
false
4
```

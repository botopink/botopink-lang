----- SOURCE CODE -- main.bp
```botopink
#[@iterator]
fn fromList<T>(xs: Array<T>) -> @Iterator<T> {
    loop (xs) { item ->
        yield item;
    };
}

fn toList<T>(iter: @Iterator<T>) -> Array<T> {
    var out = [];
    loop (iter) { item ->
        out.push(item);
    };
    return out;
}

fn main() {
    @print(toList(fromList([1, 2, 3])).join(","));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% #[@future] / #[@asyncGenerator] — eager lowering
fromList(Xs) ->
    lists:map(fun(Item) ->
        Item
    end, Xs).

toList(Iter) ->
    Out = [],
    lists:foreach(fun(Item) ->
        (Out ++ [Item])
    end, Iter),
    Out.

main() ->
    io:format("~p~n", [iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, toList(fromList([1, 2, 3])))))]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<<>>
```

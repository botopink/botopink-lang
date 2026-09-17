----- SOURCE CODE -- main.bp
```botopink
fn pick(n: i32) -> i32 { return n + 1; }
fn omit(n: i32) -> i32 { return n + 2; }
fn partial(n: i32) -> i32 { return n + 3; }
fn mergeRecords(a: i32, b: i32) -> i32 { return a + b; }
fn mapFields(n: i32) -> i32 { return n * 2; }
fn main() {
    @print(pick(1));
    @print(omit(1));
    @print(partial(1));
    @print(mergeRecords(2, 3));
    @print(mapFields(3));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

pick(N) ->
    (N + 1).

omit(N) ->
    (N + 2).

partial(N) ->
    (N + 3).

mergeRecords(A, B) ->
    (A + B).

mapFields(N) ->
    (N * 2).

main() ->
    '__bp_print'([pick(1)]),
    '__bp_print'([omit(1)]),
    '__bp_print'([partial(1)]),
    '__bp_print'([mergeRecords(2, 3)]),
    '__bp_print'([mapFields(3)]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
2
3
4
5
6
```

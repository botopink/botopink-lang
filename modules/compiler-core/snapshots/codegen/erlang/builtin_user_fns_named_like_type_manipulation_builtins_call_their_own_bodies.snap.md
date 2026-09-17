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
    io:format("~p~n", [pick(1)]),
    io:format("~p~n", [omit(1)]),
    io:format("~p~n", [partial(1)]),
    io:format("~p~n", [mergeRecords(2, 3)]),
    io:format("~p~n", [mapFields(3)]).

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

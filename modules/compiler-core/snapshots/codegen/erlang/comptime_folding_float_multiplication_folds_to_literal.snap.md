----- SOURCE CODE -- main.bp
```botopink
val pi2 = comptime {
    break 3.14 * 2.0;
};
fn main() {
    @print(pi2);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val pi2 = comptime {
          break 3.14 * 2.0;
      } → 6.28
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% comptime val pi2
pi2() ->
    (3.14 * 2.0).

main() ->
    io:format("~p~n", [pi2()]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
6.28
```

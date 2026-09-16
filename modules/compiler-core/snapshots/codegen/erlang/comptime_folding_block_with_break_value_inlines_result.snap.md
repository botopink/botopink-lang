----- SOURCE CODE -- main.bp
```botopink
val t = comptime {
    break 2 + 22;
};
fn main() {
    @print(t);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val t = comptime {
          break 2 + 22;
      } → 24
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% comptime val t
t() ->
    (2 + 22).

main() ->
    io:format("~p~n", [t()]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
24
```

----- SOURCE CODE -- main.bp
```botopink
val n = comptime {
    break 2 + 3 * 4;
};
fn main() {
    @print(n);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val n = comptime {
          break 2 + 3 * 4;
      } → 14
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% comptime val n

main() ->
    io:format("~p~n", [N]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
COMPILE ERROR (erlc):
main.erl:7:24: variable 'N' is unbound
```

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
      } → 0
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% comptime val pi2

main() ->
    io:format("~p~n", [Pi2]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
COMPILE ERROR (erlc):
main.erl:7:24: variable 'Pi2' is unbound
```

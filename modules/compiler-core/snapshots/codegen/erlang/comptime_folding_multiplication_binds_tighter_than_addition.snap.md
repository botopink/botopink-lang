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
n() ->
    (2 + (3 * 4)).

main() ->
    '__bp_print'([n()]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
14
```

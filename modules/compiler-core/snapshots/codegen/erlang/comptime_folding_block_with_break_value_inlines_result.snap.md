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
    '__bp_print'([t()]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
24
```

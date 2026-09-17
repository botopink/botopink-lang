----- SOURCE CODE -- main.bp
```botopink
val result = comptime {
    val x = 10;
    break x * 2;
};
fn main() {
    @print(result);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val result = comptime {
          val x = 10;
          break x * 2;
      } → 20
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% comptime val result
result() ->
    (X * 2).

main() ->
    '__bp_print'([result()]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
COMPILE ERROR (erlc):
main.erl:6:6: variable 'X' is unbound
```

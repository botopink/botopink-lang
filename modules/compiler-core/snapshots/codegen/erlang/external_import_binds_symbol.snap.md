----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("erlang", "abs"),
  @External.Node("./stdlib.mjs", "abs")]
pub declare fn abs(n: i32) -> i32;

fn main() {
    @print(abs(-5));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-compile({no_auto_import,[abs/1]}).
-export(['_botopink_main'/0, main/1]).

%% external fn abs -> erlang:abs

main() ->
    '__bp_print'([erlang:abs((-5))]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
5
```

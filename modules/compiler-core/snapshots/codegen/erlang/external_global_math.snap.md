----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("math", "floor"),
  @External.Node("Math", "floor")]
pub declare fn floor(n: f64) -> f64;

fn main() {
    @print(floor(1.7));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% external fn floor -> math:floor

main() ->
    '__bp_print'([math:floor(1.7)]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
1.0
```

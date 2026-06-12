----- SOURCE CODE -- main.bp
```botopink
#[@external(erlang, "erlang", "abs"),
  @external(node, "./stdlib.mjs", "abs")]
pub declare fn abs(n: i32) -> i32;

fn main() {
    @print(abs(-5));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% external fn abs -> erlang:abs

main() ->
    io:format("~p~n", [erlang:abs((-5))]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
5
```

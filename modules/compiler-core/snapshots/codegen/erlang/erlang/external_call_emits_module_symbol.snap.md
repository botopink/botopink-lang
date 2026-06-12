----- SOURCE CODE -- main.bp
```botopink
#[@external(erlang, "string", "length"),
  @external(node, "./gleam_stdlib.mjs", "string_length")]
pub declare fn str_length(s: string) -> i32;

fn main() {
    @print(str_length("hello"));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% external fn str_length -> string:length

main() ->
    io:format("~p~n", [string:length(<<"hello">>)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
5
```

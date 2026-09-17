----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("string", "length"),
  @External.Node("./gleam_stdlib.mjs", "string_length")]
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
    '__bp_print'([string:length(<<"hello">>)]).

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

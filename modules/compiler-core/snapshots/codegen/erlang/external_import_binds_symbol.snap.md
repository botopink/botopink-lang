----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("filename", "extension"),
  @External.Node("node:path", "extname")]
pub declare fn extname(p: string) -> string;

fn main() {
    @print(extname("docs/readme.md"));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% external fn extname -> filename:extension

main() ->
    '__bp_print'([filename:extension(<<"docs/readme.md">>)]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
.md
```

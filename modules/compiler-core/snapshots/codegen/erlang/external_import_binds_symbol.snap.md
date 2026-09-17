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
    io:format("~p~n", [filename:extension(<<"docs/readme.md">>)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<<".md">>
```

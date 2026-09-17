----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("filename", "basename"),
  @External.Node("node:path", "basename")]
pub declare fn basename(p: string) -> string;

fn main() {
    @print(basename("/tmp/notes.txt"));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% external fn basename -> filename:basename

main() ->
    io:format("~p~n", [filename:basename(<<"/tmp/notes.txt">>)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<<"notes.txt">>
```

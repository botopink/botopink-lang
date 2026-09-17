----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("filename", "dirname"),
  @External.Node("node:path", "dirname")]
pub declare fn dirname(p: string) -> string;

fn main() {
    @print(dirname("/tmp/notes.txt"));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% external fn dirname -> filename:dirname

main() ->
    io:format("~p~n", [filename:dirname(<<"/tmp/notes.txt">>)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<<"/tmp">>
```

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
    '__bp_print'([filename:basename(<<"/tmp/notes.txt">>)]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
notes.txt
```

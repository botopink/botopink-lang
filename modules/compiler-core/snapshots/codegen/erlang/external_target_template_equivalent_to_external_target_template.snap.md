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
    '__bp_print'([filename:dirname(<<"/tmp/notes.txt">>)]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
/tmp
```

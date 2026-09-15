----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("base64:encode($0)"),
  @External.Node("""Buffer.from($0, 'utf8').toString('base64')""")]
pub declare fn b64encode(s: string) -> string;

fn main() {
    @print(b64encode("hi"));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% external fn b64encode (no erlang target)

main() ->
    io:format("~p~n", [base64:encode(<<"hi">>)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<<"aGk=">>
```

----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("iolist_to_binary(io_lib:format(\"~p\", [$0]))"),
  @External.Node("JSON.stringify($0)")]
declare fn stringify(value: i32) -> string;

fn main() {
    @print(stringify(42));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% external fn stringify (no erlang target)

main() ->
    '__bp_print'([iolist_to_binary(io_lib:format("~p", [42]))]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
42
```

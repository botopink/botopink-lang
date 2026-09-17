----- SOURCE CODE -- main.bp
```botopink
#[@External.Node("process.pid"),
  @External.Erlang("list_to_integer(os:getpid())")]
declare fn pid() -> i32;

fn main() {
    @print(pid() > 0);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% external fn pid (no erlang target)

main() ->
    '__bp_print'([(list_to_integer(os:getpid()) > 0)]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
true
```

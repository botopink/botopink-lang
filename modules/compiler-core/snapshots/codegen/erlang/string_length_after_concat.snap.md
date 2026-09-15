----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "ab" + "cdef";
    @print(s.len);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    S = (<<"ab">> + <<"cdef">>),
    io:format("~p~n", [string:length(S)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

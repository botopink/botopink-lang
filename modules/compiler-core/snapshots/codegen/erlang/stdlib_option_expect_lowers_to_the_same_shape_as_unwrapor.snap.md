----- SOURCE CODE -- main.bp
```botopink
fn firstChar(s: string) -> ?string { @todo(); }
fn main() {
    val s = firstChar("abc").expect("");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

firstChar(S) ->
    erlang:error({todo, <<"not implemented">>}).

main() ->
    S = (fun(O) -> case O of undefined -> (<<"">>); V -> V end end)(firstChar(<<"abc">>)).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

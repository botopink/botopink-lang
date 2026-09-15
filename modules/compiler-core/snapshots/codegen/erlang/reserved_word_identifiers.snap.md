----- SOURCE CODE -- main.bp
```botopink
pub fn delete(with: string, class: string) -> string {
    val static = with + class;
    return static;
}

fn main() {
    @print(delete("a", "b"));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).
-export([delete/2]).

delete(With, Class) ->
    Static = (With + Class),
    Static.

main() ->
    io:format("~p~n", [delete(<<"a">>, <<"b">>)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

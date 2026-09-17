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
    Static = <<With/binary, Class/binary>>,
    Static.

main() ->
    '__bp_print'([delete(<<"a">>, <<"b">>)]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
ab
```

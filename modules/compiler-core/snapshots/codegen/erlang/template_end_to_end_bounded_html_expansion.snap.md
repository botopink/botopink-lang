----- SOURCE CODE -- main.bp
```botopink
pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
    return template;
}
val name = "world";
val page = html """
<p>${name}</p>
""";
fn main() {
    @print(page);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

name() ->
    <<"world">>.

page() ->
    <<"\n<p>", (name())/binary, "</p>\n">>.

main() ->
    '__bp_print'([page()]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs

<p>world</p>

```

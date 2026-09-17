----- SOURCE CODE -- main.bp
```botopink
pub fn html(comptime q: @Expr<string>) -> @Expr<string> {
    return q;
}
val name = "world";
val page = html
    \\<div>
    \\  <p>${name}</p>
    \\</div>
;
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
    <<"<div>\n  <p>", (name())/binary, "</p>\n</div>">>.

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
<div>
  <p>world</p>
</div>
```

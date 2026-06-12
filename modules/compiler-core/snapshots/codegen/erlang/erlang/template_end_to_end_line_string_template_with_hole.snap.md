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



main() ->
    io:format("~p~n", [Page]).

'_botopink_main'() ->
    Name = <<"world">>,
    Page = ((<<"<div>\n  <p>">> + Name) + <<"</p>\n</div>">>),
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

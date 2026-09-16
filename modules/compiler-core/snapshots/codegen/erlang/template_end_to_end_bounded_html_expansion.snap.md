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
    io:format("~p~n", [page()]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<<"\n<p>world</p>\n">>
```

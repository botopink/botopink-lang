----- SOURCE CODE -- view.bp
```botopink
pub fn html(comptime q: @Expr<string>) -> @Expr<string> {
    var acc = "\"\"";
    loop (q.parts()) { p ->
        if (p.kind == "Text") {
            acc = acc + " + \"" + p.text + "\"";
        };
        if (p.kind == "Interp") {
            acc = acc + " + " + p.code;
        };
    };
    return q.build(acc);
}
```

----- ERLANG -- view.erl
```erlang
-module(view).
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {html} from "view";

val name = "world";

val page = html
    \\<div>
    \\  <p>${name}</p>
    \\  <Page1/>
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

%% import html



main() ->
    io:format("~p~n", [Page]).

'_botopink_main'() ->
    Name = <<"world">>,
    Page = (((<<"">> + <<"<div>\n  <p>">>) + Name) + <<"</p>\n  <Page1/>\n</div>">>),
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

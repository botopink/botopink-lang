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

----- JAVASCRIPT -- view.js
```javascript
```

----- TYPESCRIPT TYPEDEF -- view.d.ts
```typescript

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

----- COMPTIME ERLANG -- template html
```erlang
html(Q) ->
    Acc = <<"\"\"">>,
    Acc@6 = lists:foldl(fun(P, Acc@1) ->
        Acc@3 = case (maps:get(kind, P) =:= <<"Text">>) of
            true ->
                Acc@2 = '__bp_add'('__bp_add'('__bp_add'(Acc@1, <<" + \"">>), maps:get(text, P)), <<"\"">>),
                Acc@2;
            _ ->
                Acc@1
        end,
        Acc@5 = case (maps:get(kind, P) =:= <<"Interp">>) of
            true ->
                Acc@4 = '__bp_add'('__bp_add'(Acc@3, <<" + ">>), maps:get(code, P)),
                Acc@4;
            _ ->
                Acc@3
        end,
        Acc@5
    end, Acc, parts(Q)),
    build(Q, Acc@6).

main() ->
    try
        json:encode('__bp_reply'(html(#{'__bp_capture' => <<"q">>, text => <<"<div>\n  <p>__bp_hole_q_0</p>\n  <Page1/>\n</div>">>, parts => [#{kind => <<"Text">>, text => <<"<div>\n  <p>">>, span => #{start => 0, 'end' => 11, line => 1}}, #{kind => <<"Interp">>, code => <<"__bp_hole_q_0">>, span => #{start => 11, 'end' => 24, line => 2}}, #{kind => <<"Text">>, text => <<"</p>\n  <Page1/>\n</div>">>, span => #{start => 24, 'end' => 46, line => 2}}], source => #{file => <<"">>, line => 6, col => 5}, context => #{source => #{file => <<"">>, line => 6, col => 5}, text => <<"<div>\n  <p>__bp_hole_q_0</p>\n  <Page1/>\n</div>">>, multiline => true}, bindings => [#{name => <<"html">>, kind => 'Fn'}, #{name => <<"name">>, kind => 'Val'}, #{name => <<"page">>, kind => 'Val'}, #{name => <<"main">>, kind => 'Fn'}]})))
    catch
        throw:{'__bp_template_fail', Message, Param, Span} ->
            json:encode(#{kind => <<"fail">>, message => '__bp_text'(Message), param => Param, span => '__bp_json'(Span)});
        Class:Reason ->
            json:encode(#{kind => <<"error">>, message => '__bp_text'({Class, Reason})})
    end.
```

----- COMPTIME REPLY -- template html
```json
{
  "source": "\"\" + \"<div>\n  <p>\" + __bp_hole_q_0 + \"</p>\n  <Page1/>\n</div>\"",
  "kind": "code"
}
```

----- JAVASCRIPT -- main.js
```javascript


const name = "world";

const page = ((("" + "<div>\n  <p>") + name) + "</p>\n  <Page1/>\n</div>");

function main() {
    console.log(page);
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { html } from "view";







```

----- RUN LOG -----
```logs
<div>
  <p>world</p>
  <Page1/>
</div>
```

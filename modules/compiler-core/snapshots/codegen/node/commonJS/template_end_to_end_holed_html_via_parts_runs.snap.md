----- SOURCE CODE -- main.bp
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
val name = "world";
val page = html """<p>${name}</p>""";
fn main() {
    @print(page);
}
```

----- JAVASCRIPT -- main.js
```javascript
const name = "world";

const page = ((("" + "<p>") + name) + "</p>");

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
export declare function html(q: ): Expr<string>;







```

----- RUN LOG -----
```logs
<p>world</p>
```

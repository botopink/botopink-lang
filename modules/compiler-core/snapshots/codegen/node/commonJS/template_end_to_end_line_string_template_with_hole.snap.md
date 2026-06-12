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

----- JAVASCRIPT -- main.js
```javascript
const name = "world";

const page = (("<div>\n  <p>" + name) + "</p>\n</div>");

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
<div>
  <p>world</p>
</div>
```

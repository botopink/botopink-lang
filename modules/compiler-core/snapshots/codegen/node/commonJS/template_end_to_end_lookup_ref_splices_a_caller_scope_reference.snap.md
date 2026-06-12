----- SOURCE CODE -- main.bp
```botopink
val greeting = "ola mundo";
pub fn pick(comptime q: @Expr<string>) -> @Expr<string> {
    val hit = q.lookup("greeting");
    if (hit) { b ->
        return b.ref();
    };
    return q.fail("greeting not found in caller scope");
}
val s = pick "x";
fn main() {
    @print(s);
}
```

----- JAVASCRIPT -- main.js
```javascript
const greeting = "ola mundo";

const s = greeting;

function main() {
    console.log(s);
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript


export declare function pick(q: ): Expr<string>;





```

----- RUN LOG -----
```logs
ola mundo
```

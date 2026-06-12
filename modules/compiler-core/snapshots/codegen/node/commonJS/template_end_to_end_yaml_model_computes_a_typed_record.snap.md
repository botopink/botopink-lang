----- SOURCE CODE -- main.bp
```botopink
pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
    val t = q.text();
    return @expr(record { port: 8000 + t.length, debug: true });
}
val cfg = conf "yaml";
fn main() {
    @print(cfg.port + 1);
}
```

----- JAVASCRIPT -- main.js
```javascript
const cfg = ({ port: 8004, debug: true });

function main() {
    console.log((cfg.port + 1));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare function conf(q: ): Expr<T>;





```

----- RUN LOG -----
```logs
8005
```

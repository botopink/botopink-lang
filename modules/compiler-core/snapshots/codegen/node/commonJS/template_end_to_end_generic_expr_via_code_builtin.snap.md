----- SOURCE CODE -- main.bp
```botopink
pub fn port<T>() -> @Expr<T> {
    return @code("8080");
}
fn main() {
    val p = port() + 1;
    @print(p);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const p = (8080 + 1);
    console.log(p);
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare function port(): Expr<T>;



```

----- RUN LOG -----
```logs
8081
```

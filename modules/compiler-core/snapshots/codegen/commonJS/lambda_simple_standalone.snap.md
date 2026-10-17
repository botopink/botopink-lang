----- SOURCE CODE -- main.bp
```botopink
fn main() -> string {
    val func = {s ->
        return s;
    };
    return func("hello");
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const func = (s) => {
    return s;
};
    return func("hello");
}

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```

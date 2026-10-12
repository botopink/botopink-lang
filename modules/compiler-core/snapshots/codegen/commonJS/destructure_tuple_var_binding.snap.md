----- SOURCE CODE -- main.bp
```botopink
fn main() {
    var #(x, y) = #(10, 20);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    let [ x, y ] = [10, 20];
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

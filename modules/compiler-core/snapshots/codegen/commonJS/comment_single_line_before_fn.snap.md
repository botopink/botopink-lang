----- SOURCE CODE -- main.bp
```botopink
// This is a comment
fn main() -> void {
    null;
}
```

----- JAVASCRIPT -- main.js
```javascript
// This is a comment

function main() {
    null;
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

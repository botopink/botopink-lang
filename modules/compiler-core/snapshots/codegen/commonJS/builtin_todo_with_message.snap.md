----- SOURCE CODE -- main.bp
```botopink
fn notImplemented() {
    @todo("implement this function");
}
```

----- JAVASCRIPT -- main.js
```javascript
function notImplemented() {
    (() => { throw new Error("implement this function") })();
}

Object.defineProperty(exports, "__bp_priv__", { value: { notImplemented } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```

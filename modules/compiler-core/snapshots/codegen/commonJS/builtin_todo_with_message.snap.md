----- SOURCE CODE -- main.bp
```botopink
fn notImplemented() {
    @todo("implement this function");
}
```

----- JAVASCRIPT -- main.js
```javascript
function notImplemented() {
    (() => { throw Object.defineProperty(new Error("implement this function"), '__bp_panic', { value: true }) })();
}

Object.defineProperty(exports, "__bp_priv__", { value: { notImplemented } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```

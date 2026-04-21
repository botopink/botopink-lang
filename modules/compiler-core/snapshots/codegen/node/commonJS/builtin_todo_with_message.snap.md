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
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

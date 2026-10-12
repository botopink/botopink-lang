----- SOURCE CODE -- main.bp
```botopink
fn fail() {
    @panic("something went wrong");
}
```

----- JAVASCRIPT -- main.js
```javascript
function fail() {
    (() => { throw new Error("something went wrong") })();
}

Object.defineProperty(exports, "__bp_priv__", { value: { fail } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```

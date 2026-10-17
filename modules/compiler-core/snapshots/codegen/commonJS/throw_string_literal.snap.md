----- SOURCE CODE -- main.bp
```botopink
fn fail() {
    throw "something went wrong";
}
```

----- JAVASCRIPT -- main.js
```javascript
function fail() {
    throw "something went wrong";
}

Object.defineProperty(exports, "__bp_priv__", { value: { fail } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```

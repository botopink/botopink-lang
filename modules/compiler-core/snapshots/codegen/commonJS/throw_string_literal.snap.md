----- SOURCE CODE -- main.bp
```botopink
fn fail() -> Result<void, string> {
    throw "something went wrong";
    return;
}
```

----- JAVASCRIPT -- main.js
```javascript
function fail() {
    return ({ error: "something went wrong" });
    return ({ ok: null });
}

Object.defineProperty(exports, "__bp_priv__", { value: { fail } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
fn sameWord() -> bool {
    return "foo" == "bar";
}
```

----- JAVASCRIPT -- main.js
```javascript
function sameWord() {
    return ("foo" === "bar");
}

Object.defineProperty(exports, "__bp_priv__", { value: { sameWord } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```

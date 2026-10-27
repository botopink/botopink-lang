----- SOURCE CODE -- main.bp
```botopink
fn f() -> Result<void, string> {
    val greeting = "hello";
    val assert "hello" = greeting catch throw "not hello";
    return;
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    const greeting = "hello";
    let _assert0 = greeting;
    if (!((_assert0 === "hello"))) { return ({ error: "not hello" }); }
    return ({ ok: null });
}

Object.defineProperty(exports, "__bp_priv__", { value: { f } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
fn sign(n: i32) -> string {
    val r = if (n > 0) { "positive"; };
    @print(r);
    return r;
}
```

----- JAVASCRIPT -- main.js
```javascript
function sign(n) {
    const r = (() => { if ((n > 0)) { return "positive"; } })();
    console.log(r);
    return r;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```

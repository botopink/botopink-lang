----- SOURCE CODE -- main.bp
```botopink
fn make() -> i32 {
    val r = record { a: 7, b: 11 };
    return r;
}
```

----- JAVASCRIPT -- main.js
```javascript
function make() {
    const r = ({ a: 7, b: 11 });
    return r;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```

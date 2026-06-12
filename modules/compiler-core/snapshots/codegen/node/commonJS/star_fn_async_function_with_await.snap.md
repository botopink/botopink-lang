----- SOURCE CODE -- main.bp
```botopink
*fn fetch(x: i32) -> @Future<i32> {
    return x;
}
*fn loadTwice(x: i32) -> @Future<i32> {
    val a = await fetch(x);
    return a + a;
}
```

----- JAVASCRIPT -- main.js
```javascript
async function fetch(x) {
    return x;
}

async function loadTwice(x) {
    const a = await fetch(x);
    return (a + a);
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```

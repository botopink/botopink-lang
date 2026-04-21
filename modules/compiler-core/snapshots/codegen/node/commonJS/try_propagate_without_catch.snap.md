----- SOURCE CODE -- main.bp
```botopink
fn fetch() -> i32 {
    @todo();
}
fn process() -> i32 {
    val r = try fetch();
    return r;
}
```

----- JAVASCRIPT -- main.js
```javascript
function fetch() {
    (() => { throw new Error("not implemented") })();
}

function process() {
    const r = fetch();
    return r;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

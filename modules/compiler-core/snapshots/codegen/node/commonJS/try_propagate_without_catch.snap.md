----- SOURCE CODE -- main.bp
```botopink
fn fetch() -> i32 {
    @todo();
}
fn process() -> i32 {
    val r = try fetch();
    @print(r);
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

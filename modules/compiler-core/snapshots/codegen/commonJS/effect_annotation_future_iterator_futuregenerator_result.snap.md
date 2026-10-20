----- SOURCE CODE -- main.bp
```botopink
async fn fetch(x: i32) -> Async<i32> {
    return x;
}
iter fn counter() -> Iter<i32> {
    yield 1;
    yield 2;
}
async iter fn stream() -> AsyncIter<Result<i32, string>> {
    yield 1;
}
fn parse(n: i32) -> Result<i32, string> {
    if (n < 0) { throw "negative"; };
    return n;
}
```

----- JAVASCRIPT -- main.js
```javascript
async function fetch(x) {
    return x;
}

function* counter() {
    yield 1;
    yield 2;
}

async function* stream() {
    yield ({ ok: 1 });
}

function parse(n) {
    if ((n < 0)) { return ({ error: "negative" }); }
    return ({ ok: n });
}

Object.defineProperty(exports, "__bp_priv__", { value: { fetch, counter, stream, parse } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
```

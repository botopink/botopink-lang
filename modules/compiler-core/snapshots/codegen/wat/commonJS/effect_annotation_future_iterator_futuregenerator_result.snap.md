----- SOURCE CODE -- main.bp
```botopink
#[@future]
fn fetch(x: i32) -> @Future<i32> {
    return x;
}
#[@resultGenerator]
fn counter() -> @ResultGenerator<i32> {
    yield 1;
    yield 2;
}
#[@futureGenerator]
fn stream() -> @FutureGenerator<i32, string> {
    yield 1;
}
#[@result]
fn parse(n: i32) -> @Result<i32, string> {
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
    yield 1;
}

function parse(n) {
    if ((n < 0)) { return ({ error: "negative" }); }
    return ({ ok: n });
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
```

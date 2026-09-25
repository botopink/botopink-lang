----- SOURCE CODE -- main.bp
```botopink
pub fn loadOne(x: i32) -> @Task<i32> {
    return x;
}
pub fn count() -> @Iterator<i32> {
    yield 1;
}
pub fn pulses() -> @Stream<@Result<i32, string>> {
    yield 1;
}
```

----- JAVASCRIPT -- main.js
```javascript
async function loadOne(x) {
    return x;
}
exports.loadOne = loadOne;

function* count() {
    yield 1;
}
exports.count = count;

async function* pulses() {
    yield ({ ok: 1 });
}
exports.pulses = pulses;
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare function loadOne(x: number): Promise<number>;


export declare function count(): IterableIterator<number>;


export declare function pulses(): AsyncGenerator<{ tag: "Ok"; result: number } | { tag: "Error"; error: string }>;

```

----- RUN LOG -----
```logs
```

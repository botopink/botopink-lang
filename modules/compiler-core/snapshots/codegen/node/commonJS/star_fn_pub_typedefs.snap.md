----- SOURCE CODE -- main.bp
```botopink
pub *fn loadOne(x: i32) -> @Future<i32> {
    return x;
}
pub *fn count() -> @Iterator<i32> {
    yield 1;
}
pub *fn pulses() -> @AsyncIterator<i32, string> {
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
    yield 1;
}
exports.pulses = pulses;
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare function loadOne(x: ): Promise<i32>;


export declare function count(): IterableIterator<i32>;


export declare function pulses(): AsyncIterableIterator<i32>;

```

----- RUN LOG -----
```logs
```

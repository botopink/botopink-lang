----- SOURCE CODE -- main.bp
```botopink
#[@future]
pub fn loadOne(x: i32) -> @Future<i32> {
    return x;
}
#[@iterator]
pub fn count() -> @Iterator<i32> {
    yield 1;
}
#[@futureGenerator]
pub fn pulses() -> @FutureGenerator<i32, string> {
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
export declare function loadOne(x: number): Promise<number>;


export declare function count(): IterableIterator<number>;


export declare function pulses(): AsyncGenerator<number>;

```

----- RUN LOG -----
```logs
```

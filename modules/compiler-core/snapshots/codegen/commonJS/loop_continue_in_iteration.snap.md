----- SOURCE CODE -- main.bp
```botopink
fn sumEvens(arr: i32[]) -> i32[] {
    return for (arr) { x ->
        if (x % 2 != 0) { continue; };
        yield x;
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function sumEvens(arr) {
    return (() => {
        const _acc = [];
        for (const x of arr) {
            if (((x % 2) !== 0)) { continue; }
            _acc.push(x);
        }
        return _acc;
    })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```

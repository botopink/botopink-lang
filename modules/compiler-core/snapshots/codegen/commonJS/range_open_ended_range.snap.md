----- SOURCE CODE -- main.bp
```botopink
fn countUp(x: i32) {
    for (x..) { i ->
        if (i > 100) {
          break;
        };
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function* __bp_range_from(n) { while (true) { yield n; n += 1; } }

function countUp(x) {
    for (const i of __bp_range_from(x)) {
    if ((i > 100)) { break; }
}
}

Object.defineProperty(exports, "__bp_priv__", { value: { countUp } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```

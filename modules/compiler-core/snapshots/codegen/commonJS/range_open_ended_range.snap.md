----- SOURCE CODE -- main.bp
```botopink
fn countUp(x: i32) {
    loop (x..) { i ->
        if (i > 100) {
          break;
        };
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function countUp(x) {
    for (const i of (() => { throw new Error("open-ended range unsupported on commonJS"); })()) {
    (() => { if ((i > 100)) { return return; } })();
};
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```

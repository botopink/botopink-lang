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
    for (const [i] of Object.entries(x..)) {
    (() => { if ((i > 100)) { return return; } })();
};
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

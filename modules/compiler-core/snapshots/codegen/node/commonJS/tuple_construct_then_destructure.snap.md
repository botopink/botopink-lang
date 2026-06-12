----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val t = #(10, 20);
    val #(a, b) = t;
    @print(a + b);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const t = [10, 20];
    const [ a, b ] = t;
    console.log((a + b));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
30
```

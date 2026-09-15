----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val labels = ["a", "bb", "ccc"];
    @print(labels.len);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const labels = ["a", "bb", "ccc"];
    console.log(labels.len);
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
undefined
```

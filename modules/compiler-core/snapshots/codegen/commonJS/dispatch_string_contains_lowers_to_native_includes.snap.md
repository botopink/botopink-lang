----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val hw = "hello world";
    @print(hw.contains("world"));
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const hw = "hello world";
    console.log(hw.includes("world"));
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
true
```

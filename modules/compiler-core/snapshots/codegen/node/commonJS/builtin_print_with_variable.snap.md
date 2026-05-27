----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val name = "world";
    @print("Hello, " + name);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const name = "world";
    console.log(("Hello, " + name));
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
Hello, world
```

----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "Hello,World";
    @print(s.toUpper());
    @print(s.toLower());
    @print(s.split(",").join("|"));
    @print(s.slice(0, 5));
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const s = "Hello,World";
    console.log(s.toUpperCase());
    console.log(s.toLowerCase());
    console.log(s.split(",").join("|"));
    console.log(s.slice(0, 5));
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
HELLO,WORLD
hello,world
Hello|World
Hello
```

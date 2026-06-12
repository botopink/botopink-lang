----- SOURCE CODE -- main.bp
```botopink
fn main() {
    var count = 0;
    count += 1;
    @print(count);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    let count = 0;
    count += 1;
    console.log(count);
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
1
```

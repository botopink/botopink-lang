----- SOURCE CODE -- main.bp
```botopink
val add = { x, y ->
    x + y;
};
val result = add(10, 20);
fn main() {
    @print(result);
}
```

----- JAVASCRIPT -- main.js
```javascript
const add = (x, y) => {
    return (x + y);
};

const result = add(10, 20);

function main() {
    console.log(result);
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

----- SOURCE CODE -- main.bp
```botopink
val ids = [10, 20, 30];
val dobrados = loop (ids) { id ->
    break id * 2;
};
fn main() {
    @print(dobrados);
}
```

----- JAVASCRIPT -- main.js
```javascript
const ids = [10, 20, 30];

const dobrados = (() => {
    const _acc = [];
    for (const id of ids) {
        _acc.push((id * 2));
    }
    return _acc;
})();

function main() {
    console.log(dobrados);
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
[ 20, 40, 60 ]
```

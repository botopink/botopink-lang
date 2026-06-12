----- SOURCE CODE -- main.bp
```botopink
fn main() {
    loop (0..10) { i ->
        @print(i);
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    for (const i of Array.from({length: Math.max(0, (10) - (0))}, (_, __i) => (0) + __i)) {
    console.log(i);
};
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
0
1
2
3
4
5
6
7
8
9
```

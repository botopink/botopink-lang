----- SOURCE CODE -- main.bp
```botopink
fn firstAndRest(xs: Array<i32>) -> #(Array<i32>, ?i32) {
    val head = xs.at(0);
    val rest = xs.slice(1, xs.length);
    return #(rest, head);
}

fn main() {
    val result = firstAndRest([1, 2, 3]);
    val head = result._1;
    @print(head.unwrapOr(-1));
    val empty = firstAndRest([]);
    @print(empty._1 == null);
}
```

----- JAVASCRIPT -- main.js
```javascript
function firstAndRest(xs) {
    const head = xs.at(0);
    const rest = xs.slice(1, xs.length);
    return [rest, head];
}

function main() {
    const result = firstAndRest([1, 2, 3]);
    const head = result[1];
    console.log(((_o) => _o != null ? _o : ((-1)))(head));
    const empty = firstAndRest([]);
    console.log((empty[1] == null));
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
true
```

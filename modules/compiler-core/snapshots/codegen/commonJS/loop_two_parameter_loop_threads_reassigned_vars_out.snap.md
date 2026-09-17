----- SOURCE CODE -- main.bp
```botopink
fn pick(xs: Array<string>) -> string {
    var first = "";
    var last = "";
    loop (xs) { x, i ->
        if (i == 0) { first = x; };
        last = x;
    };
    return first + "-" + last;
}
fn weigh(xs: Array<i32>) -> i32 {
    var total = 0;
    loop (xs, 1..) { x, i ->
        total = total + x * i;
    };
    return total;
}
fn main() {
    @print(pick(["a", "b", "c"]));
    @print(weigh([10, 20, 30]));
}
```

----- JAVASCRIPT -- main.js
```javascript
function pick(xs) {
    let first = "";
    let last = "";
    for (const [i, x] of (xs).entries()) {
    (() => { if ((i === 0)) { return first = x; } })();
    last = x;
};
    return ((first + "-") + last);
}

function weigh(xs) {
    let total = 0;
    for (const [i, x] of (xs).entries()) {
    total = (total + (x * i));
};
    return total;
}

function main() {
    console.log(pick(["a", "b", "c"]));
    console.log(weigh([10, 20, 30]));
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
a-c
80
```

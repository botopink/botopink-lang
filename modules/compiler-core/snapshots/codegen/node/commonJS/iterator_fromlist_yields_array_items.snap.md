----- SOURCE CODE -- main.bp
```botopink
*fn fromList<T>(xs: Array<T>) -> @Iterator<T> {
    loop (xs) { item ->
        yield item;
    };
}

*fn doRange(cur: i32, stop: i32) -> @Iterator<i32> {
    if (cur < stop) {
        yield cur;
        return doRange(cur + 1, stop);
    };
}

fn toList<T>(iter: @Iterator<T>) -> Array<T> {
    var out = [];
    loop (iter) { item ->
        out.push(item);
    };
    return out;
}

fn main() {
    @print(toList(fromList([1, 2, 3])).join(","));
    @print(toList(doRange(0, 3)).join(","));
}
```

----- JAVASCRIPT -- main.js
```javascript
function* fromList(xs) {
    for (const item of xs) {
    yield item;
};
}

function* doRange(cur, stop) {
     if ((cur < stop)) { yield cur; yield* doRange((cur + 1), stop); return; };
}

function toList(iter) {
    let out = [];
    for (const item of iter) {
    out.push(item);
};
    return out;
}

function main() {
    console.log(toList(fromList([1, 2, 3])).join(","));
    console.log(toList(doRange(0, 3)).join(","));
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
1,2,3
0,1,2
```

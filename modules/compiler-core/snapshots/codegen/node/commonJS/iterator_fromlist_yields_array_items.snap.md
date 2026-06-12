----- SOURCE CODE -- main.bp
```botopink
#[@iterator]
fn fromList<T>(xs: Array<T>) -> @Iterator<T> {
    loop (xs) { item ->
        yield item;
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
}
```

----- JAVASCRIPT -- main.js
```javascript
function* fromList(xs) {
    for (const item of xs) {
    yield item;
};
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
```

----- SOURCE CODE -- main.bp
```botopink
fn double(x: i32) -> i32 { return x * 2; }
fn inc(x: i32) -> i32 { return x + 1; }
fn main() {
    val result = 1
        |> double
        |> inc;
    @print(result);
}
```

----- JAVASCRIPT -- main.js
```javascript
function double(x) {
    return (x * 2);
}

function inc(x) {
    return (x + 1);
}

function main() {
    const result = (inc((double(1))));
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
3
```

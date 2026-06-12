----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32 }
fn describe(p: Point) -> i32 {
    val { x, y } = p;
    @print(x, y);
    return x;
}
fn main() {
    describe(Point(x: 3, y: 4));
}
```

----- JAVASCRIPT -- main.js
```javascript
class Point {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }
}

function describe(p) {
    const { x, y } = p;
    console.log(x, y);
    return x;
}

function main() {
    describe(new Point(3, 4));
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
3 4
```

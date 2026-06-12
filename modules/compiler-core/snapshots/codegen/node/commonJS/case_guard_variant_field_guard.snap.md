----- SOURCE CODE -- main.bp
```botopink
val Shape = enum {
    Circle(r: i32),
    Square(s: i32),
}
fn big(sh: Shape) -> string {
    return case sh {
        Circle(r) if r > 10 -> "big circle";
        _ -> "other";
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
const Shape = Object.freeze({
    Circle: (r) => ({ tag: "Circle", r }),
    Square: (s) => ({ tag: "Square", s }),
});

function big(sh) {
    return (() => {
        const _s = sh;
        if (_s.tag === "Circle") {
            const { r } = _s;
            if ((r > 10)) return "big circle";
        }
        return "other";
    })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```

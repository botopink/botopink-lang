----- SOURCE CODE -- main.bp
```botopink
enum Shape {
    Circle(r: i32),
    Square(side: i32),
}
fn makeCircle() -> Shape {
    return Shape.Circle(r: 5);
}
```

----- JAVASCRIPT -- main.js
```javascript
const Shape = Object.freeze({
    Circle: (r) => ({ tag: "Circle", r }),
    Square: (side) => ({ tag: "Square", side }),
});

function makeCircle() {
    return Shape.Circle(5);
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
val Shape = enum {
    Circle(radius: f64),
    Rectangle(width: f64, height: f64),
    Point,
};
val area = fn(s: Shape) -> f64 {
    case s {
        Circle(r) -> 3.14 * r * r;
        Rectangle(w, h) -> w * h;
        Point -> 0.0;
    }
};
```


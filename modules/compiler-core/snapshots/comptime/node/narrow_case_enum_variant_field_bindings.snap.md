----- SOURCE CODE -- main.bp
```botopink
enum Shape {
    Circle(radius: f64),
    Rectangle(w: f64, h: f64),
    Point,
}
fn area(s: Shape) -> f64 {
    return case s {
        Circle(radius) -> 3.14 * radius * radius;
        Rectangle(w, h) -> w * h;
        Point -> 0.0;
    };
}
@print(area(Shape.Circle(2.0)));
```


----- SOURCE CODE
type Shape {
    Circle(radius: f64),
    Square(side: f64),
}
fn bad(s: Shape) -> f64 {
    return case s {
        Circle(radius) -> radius;
        Square(side) -> radius;
    };
}

----- ERROR
error: unbound variable
  ┌─ main.bp:8:25
  │
8 │         Square(side) -> radius;
  │                         ^

  'radius' is not in scope

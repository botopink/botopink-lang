----- SOURCE CODE
val Drawable = behavior {
    fn draw(self: Self);
};
val Circle = type(radius: f64);
val CircleDrawing = implement Drawable for Circle {
    fn Renderable.draw(self: Self) {
        @print("draw");
    }
};

----- ERROR
error: unknown interface
  ┌─ main.bp:6:8
  │
6 │     fn Renderable.draw(self: Self) {
  │        ^

  'Renderable' is not a behavior implemented here (method 'draw')

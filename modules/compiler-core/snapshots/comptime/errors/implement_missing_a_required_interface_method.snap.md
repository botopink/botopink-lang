----- SOURCE CODE
val Drawable = behavior {
    fn draw(self: Self);
    fn erase(self: Self);
};
val Circle = type(radius: f64);
val CircleDrawing = implement Drawable for Circle {
    fn draw(self: Self) {
        @print("draw");
    }
};

----- ERROR
error: missing interface method
  ┌─ main.bp:6:21
  │
6 │ val CircleDrawing = implement Drawable for Circle {
  │                     ^

  'Circle' does not implement 'erase' required by behavior 'Drawable'

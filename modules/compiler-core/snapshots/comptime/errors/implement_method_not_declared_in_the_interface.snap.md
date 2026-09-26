----- SOURCE CODE
val Drawable = behavior {
    fn draw(self: Self);
};
val Circle = type(radius: f64);
val CircleDrawing = implement Drawable for Circle {
    fn draw(self: Self) {
        @print("draw");
    }
    fn explode(self: Self) {
        @print("boom");
    }
};

----- ERROR
error: unknown method
  ┌─ :9:8
  │
9 │     fn explode(self: Self) {
  │        ^

  'explode' is not declared in any behavior implemented for 'Circle'

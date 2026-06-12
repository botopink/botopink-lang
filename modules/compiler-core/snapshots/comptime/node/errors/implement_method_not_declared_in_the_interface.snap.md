----- SOURCE CODE
val Drawable = interface {
    fn draw(self: Self),
};
val Circle = record { radius: f64 };
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

  'explode' is not declared in any interface implemented for 'Circle'

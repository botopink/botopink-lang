----- SOURCE CODE
val Drawable = interface {
    fn draw(self: Self),
    fn erase(self: Self),
};
val Circle = record { radius: f64 };
val CircleDrawing = implement Drawable for Circle {
    fn draw(self: Self) {
        @print("draw");
    }
};

----- ERROR
error: missing interface method

  'Circle' does not implement 'erase' required by interface 'Drawable'

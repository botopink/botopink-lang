----- SOURCE CODE
val Drawable = interface {
    fn draw(self: Self),
};
val Circle = record { radius: f64 };
val CircleDrawing = implement Drawable for Circle {
    fn Renderable.draw(self: Self) {
        @print("draw");
    }
};

----- ERROR
error: unknown interface

  'Renderable' is not an interface implemented here (method 'draw')

----- SOURCE CODE
val Drawable = behavior {
    fn draw(self: Self) -> void;
};
val Circle = type(radius: f64);
val CircleDrawing = implement Drawable for Circle {
    fn Renderable.draw(self: Self) -> void {
        print("draw");
    }
};

import {io.terminal.print} from "std";

----- ERROR
error: unknown interface
  ┌─ main.bp:6:8
  │
6 │     fn Renderable.draw(self: Self) -> void {
  │        ^

  'Renderable' is not a behavior implemented here (method 'draw')

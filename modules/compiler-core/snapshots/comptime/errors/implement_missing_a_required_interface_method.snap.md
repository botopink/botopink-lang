----- SOURCE CODE
val Drawable = behavior {
    fn draw(self: Self) -> void;
    fn erase(self: Self) -> void;
};
val Circle = type(radius: f64);
val CircleDrawing = implement Drawable for Circle {
    fn draw(self: Self) -> void {
        print("draw");
    }
};

import {io.terminal.print} from "std";

----- ERROR
error: missing interface method
  ┌─ main.bp:6:21
  │
6 │ val CircleDrawing = implement Drawable for Circle {
  │                     ^

  'Circle' does not implement 'erase' required by behavior 'Drawable'

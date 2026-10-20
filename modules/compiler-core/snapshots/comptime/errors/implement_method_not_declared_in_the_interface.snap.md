----- SOURCE CODE
val Drawable = behavior {
    fn draw(self: Self) -> void;
};
val Circle = type(radius: f64);
val CircleDrawing = implement Drawable for Circle {
    fn draw(self: Self) -> void {
        print("draw");
    }
    fn explode(self: Self) -> void {
        print("boom");
    }
};

import {io.terminal.print} from "std";

----- ERROR
error: unknown method
  ┌─ main.bp:9:8
  │
9 │     fn explode(self: Self) -> void {
  │        ^

  'explode' is not declared in any behavior implemented for 'Circle'

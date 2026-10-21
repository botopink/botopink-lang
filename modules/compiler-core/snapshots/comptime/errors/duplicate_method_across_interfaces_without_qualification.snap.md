----- SOURCE CODE
val UsbCharger = behavior {
    fn connect(self: Self) -> void;
};
val SolarCharger = behavior {
    fn connect(self: Self) -> void;
};
val Camera = type(battery: i32);
val CameraCharger = implement UsbCharger, SolarCharger for Camera {
    fn connect(self: Self) -> void {
        print("connect");
    }
};

import {io.terminal.print} from "std";

----- ERROR
error: ambiguous method
  ┌─ main.bp:9:8
  │
9 │     fn connect(self: Self) -> void {
  │        ^

  'connect' is declared by both 'UsbCharger' and 'SolarCharger' — qualify it

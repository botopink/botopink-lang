----- SOURCE CODE
val UsbCharger = behavior {
    fn connect(self: Self);
};
val SolarCharger = behavior {
    fn connect(self: Self);
};
val Camera = type(battery: i32);
val CameraCharger = implement UsbCharger, SolarCharger for Camera {
    fn connect(self: Self) {
        @print("connect");
    }
};

----- ERROR
error: ambiguous method
  ┌─ main.bp:9:8
  │
9 │     fn connect(self: Self) {
  │        ^

  'connect' is declared by both 'UsbCharger' and 'SolarCharger' — qualify it

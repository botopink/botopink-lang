----- SOURCE CODE
val UsbCharger = interface {
    fn connect(self: Self),
};
val SolarCharger = interface {
    fn connect(self: Self),
};
val Camera = record { battery: i32 };
val CameraCharger = implement UsbCharger, SolarCharger for Camera {
    fn connect(self: Self) {
        @print("connect");
    }
};

----- ERROR
error: ambiguous method

  'connect' is declared by both 'UsbCharger' and 'SolarCharger' — qualify it
